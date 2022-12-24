---
title: "Fast string to integer conversion (C/C++)"
link: "2022-02-05"
author: "Łukasz Podkalicki"
---

This article presents a few fast and lightweight implementations of conversion
from ASCII string to integer. It can be an interesting fit to use in a small
microcontrollers like for example ATtiny13, which resources are very limited.
All presented functions are simplified and require a null-terminated array
of chars as an argument.

## Convert string to uint8_t

```c++
#include <assert.h>
#include <stdint.h>
#include <stdio.h> 

uint8_t atou8(const char *s)
{
	uint8_t v = 0;
    	while (*s) { v = (v << 1) + (v << 3) + (*(s++) - '0'); }
    	return v;
}

int main(void)
{
	const char *test_values[] = {"123", "255", "0", "11", "34", "190"};
	const uint8_t expected_values[] = {123, 255, 0, 11, 34, 190};

	for (uint8_t i = 0; i < sizeof(expected_values) / sizeof(uint8_t); ++i)
	{
		const uint8_t converted_value = atou8(test_values[i]);
		assert(converted_value == expected_values[i]);
	}

	return (0);
}
```

## Convert string to int8_t

```c++
#include <assert.h>
#include <stdint.h>
#include <stdio.h> 

int8_t atoi8(const char *s)
{
	int8_t sign = 1;
	int8_t v = 0;

	while (*s && (*s < 48 || *s > 57))
	{
		if (*(s++) == '-')
		{
			sign = -1;
			break;
		}
	}

    	while (*s)
	{
		v = (v << 1) + (v << 3) + (*(s++) - '0');
	}

	return sign * v;
}

int main(void)
{
	const char *test_values[] = {"127", "25", "0", "11", "34", "-128"};
	const int8_t expected_values[] = {127, 25, 0, 11, 34, -128};

	for (uint8_t i = 0; i < sizeof(expected_values) / sizeof(int8_t); ++i)
	{
		const int8_t converted_value = atoi8(test_values[i]);
		assert(converted_value == expected_values[i]);
	}

	return (0);
}
```

## Convert string to uint16_t

```c++
#include <assert.h>
#include <stdint.h>
#include <stdio.h> 

uint16_t atou16(const char *s)
{
	uint16_t v = 0;
    	while (*s) { v = (v << 1) + (v << 3) + (*(s++) - '0'); }
    	return v;
}

int main(void)
{
	const char *test_values[] = {"123", "65535", "0", "789", "56100", "100", "1"};
	const uint16_t expected_values[] = {123U, 65535U, 0, 789U, 56100U, 100U, 1U};

	for (uint8_t i = 0; i < sizeof(expected_values) / sizeof(uint16_t); ++i)
	{
		const uint16_t converted_value = atou16(test_values[i]);
		assert(converted_value == expected_values[i]);
	}

	return (0);
}
```

## Convert string to int16_t

```c++
#include <assert.h>
#include <stdint.h>
#include <stdio.h> 

int16_t atoi16(const char *s)
{
	int8_t sign = 1;
	int16_t v = 0;

	while (*s && (*s < 48 || *s > 57))
	{
		if (*(s++) == '-')
		{
			sign = -1;
			break;
		}
	}

    	while (*s)
	{
		v = (v << 1) + (v << 3) + (*(s++) - '0');
	}

	return sign * v;
}

int main(void)
{
	const char *test_values[] = {"32767", "25", "0", "11", "34", "-128", "-698", "-32768"};
	const int16_t expected_values[] = {32767, 25, 0, 11, 34, -128, -698, -32768};

	for (uint8_t i = 0; i < sizeof(expected_values) / sizeof(int16_t); ++i)
	{
		const int16_t converted_value = atoi16(test_values[i]);
		assert(converted_value == expected_values[i]);
	}

	return (0);
}
```

## Convert string to uint32_t

```c++
#include <assert.h>
#include <stdint.h>
#include <stdio.h>

uint32_t atou32(const char *s)
{
	uint32_t v = 0;
    	while (*s) { v = (v << 1) + (v << 3) + (*(s++) - '0'); }
    	return v;
}

int main(void)
{
	const char *test_values[] = {"123", "65535", "0", "789", "56100", "100", "1", "4294967295"};
	const uint32_t expected_values[] = {123UL, 65535UL, 0, 789UL, 56100UL, 100UL, 1UL, 4294967295UL};

	for (uint8_t i = 0; i < sizeof(expected_values) / sizeof(uint32_t); ++i)
	{
		const uint32_t converted_value = atou32(test_values[i]);
		assert(converted_value == expected_values[i]);
	}

	return (0);
}
```

## Convert string to int32_t

```c++
#include <assert.h>
#include <stdint.h>
#include <stdio.h>

int32_t atoi32(const char *s)
{
	int8_t sign = 1;
	int32_t v = 0;

	while (*s && (*s < 48 || *s > 57))
	{
		if (*(s++) == '-')
		{
			sign = -1;
			break;
		}
	}

    	while (*s)
	{
		v = (v << 1) + (v << 3) + (*(s++) - '0');
	}

	return sign * v;
}

int main(void)
{
	const char *test_values[] = {"2147483647", "32767", "25", "0", "11", "34", "-128", "-698", "-32768", "-2147483648"};
	const int32_t expected_values[] = {2147483647L, 32767L, 25L, 0, 11L, 34L, -128L, -698L, -32768L, -2147483648L};

	for (uint8_t i = 0; i < sizeof(expected_values) / sizeof(int32_t); ++i)
	{
		const int32_t converted_value = atoi32(test_values[i]);
		assert(converted_value == expected_values[i]);
	}

	return (0);
}
```
