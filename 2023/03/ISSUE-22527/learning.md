# Learning

## Linux Connection Tracking
### 참조자료
* https://arthurchiao.art/blog/conntrack-design-and-implementation/#1-introduction


## iproute2 BPF
### 참조자료
* https://docs.cilium.io/en/stable/bpf/toolchain/#iproute2
* https://github.com/cilium/iproute2/blob/libbpf-static-data/include/bpf_elf.h

### 개요
BPF 프로그램을 커널에 적재하는 다양한 프론트앤드들이 존재하는것을 확인.\
`bcc`, `perf`, `iproute2`가 대표적임.\
`Cilium`의 `BPF Loader`는 `XDP`, `tc`, `lwt`유형의 네트워킹 프로그램을 로드하기 위해  `iproute2 BPF Loade`로 구현되었음.\
향후 `Cilium`은 `native BPF Loader`를 탑재할 예정이지만, 개발 및 디버깅을 용이하게 하기 위해 `iporoute2` 제품군을 통해 로드할 수 있도록 호환될 것.

### [struct bpf_elf_map](https://github.com/cilium/iproute2/blob/libbpf-static-data/include/bpf_elf.h)
`iproute2`가 제공하는 `struct bpf_elf_map`에 대해 주목할 필요가 있음.\
상당수의 코드에서 `__section_tail(ID, KEY)`macro를 사용하는것을 볼 수 있음.
* **example**
	```c
	[...]

	#ifndef __stringify
	# define __stringify(X)   #X
	#endif

	#ifndef __section
	# define __section(NAME)                  \
	__attribute__((section(NAME), used))
	#endif

	#ifndef __section_tail
	# define __section_tail(ID, KEY)          \
	__section(__stringify(ID) "/" __stringify(KEY))
	#endif

	#ifndef BPF_FUNC
	# define BPF_FUNC(NAME, ...)              \
	(*NAME)(__VA_ARGS__) = (void *)BPF_FUNC_##NAME
	#endif

	#define BPF_JMP_MAP_ID   1

	static void BPF_FUNC(tail_call, struct __sk_buff *skb, void *map,
						uint32_t index);

	struct bpf_elf_map jmp_map __section("maps") = {
		.type           = BPF_MAP_TYPE_PROG_ARRAY,
		.id             = BPF_JMP_MAP_ID,
		.size_key       = sizeof(uint32_t),
		.size_value     = sizeof(uint32_t),
		.pinning        = PIN_GLOBAL_NS,
		.max_elem       = 1,
	};

	__section_tail(BPF_JMP_MAP_ID, 0)
	int looper(struct __sk_buff *skb)
	{
		printk("skb cb: %u\n", skb->cb[0]++);
		tail_call(skb, &jmp_map, 0);
		return TC_ACT_OK;
	}

	__section("prog")
	int entry(struct __sk_buff *skb)
	{
		skb->cb[0] = 0;
		tail_call(skb, &jmp_map, 0);
		return TC_ACT_OK;
	}

	char __license[] __section("license") = "GPL";
	```
`iproute2`의 `BPF Loader`의 경우 위 예시코드를 로딩하면서 `__section_tail()`로 표시된 섹션도 인식함.\
`__section_tail(ID, KEY)`에서 ID를 기반으로 `bpf_elf_map`이 제공하는 id와 비교하여 입력된 KEY를 통해 해당 인덱스에 적재됨.\
결과적으로 제공된 모든 테일 호출 섹션은 `iproute2`의 `BPF Loader`에 의해 해당 맵으로 적재됨.\
해당 메커니즘은 `tc`뿐만 아니라 `iproute2`가 지원하는 다른 BPF 프로그램 유형(`XDP`, `lwt`)에도 적용 가능.