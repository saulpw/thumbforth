#include <stddef.h>
#include <limits.h>

static int strncmp(const char *a, const char *b, int n)
{
    while (*a && *b && *a == *b && n > 0) {
        a++;
        b++;
        n--;
    }

    if (!*a && !*b) return 0;
    if (!*a) return -1;
    if (!*b) return +1;
    return (*b - *a);
}

static int isdigit(int c)
{
    return '0' <= c && c <= '9';
}

static int isspace(int c)
{
    switch (c) {
    case ' ':
    case '\n':
    case '\t':
    case 13:
        return 1;
    default:
        return 0;
    };
}

// copy ASCIIZ input to out, stopping at delim (terminating out with NUL)
// delim can be 0, meaning all whitespace
// returns number of characters consumed from input

int parse_token(char *out, const char *start_input)
{
    char ch;
    int n = 0;
    const char *input = start_input;

    while (*input && isspace((int) *input)) {
        input++;
    }

    while ((ch = *input++)) {
        if (isspace(ch)) break;
        out[n++] = ch;
    }

    out[n++] = 0;
    return input - start_input;
}

int parse_string(char delim, char *out, const char *input)
{
    char ch;
    int n = 0;

    while ((ch = *input++)) {
        if (ch == delim) break;
        out[n++] = ch;
    }

    out[n++] = 0;

    return n;
}

typedef struct dictentry_t {
    struct dictentry_t *prev;
    char name[16];
    int data[];
} dictentry_t;

dictentry_t *
find_entry(const char *name, dictentry_t *LAST)
{
    dictentry_t *d = LAST;

    for (d=LAST; d; d = d->prev) {
        if (!strncmp(name, d->name, 16)) {
            return d;
        }
    }
    return NULL;
}

int
atoi(const char *str)
{
    int r=0;
    char sign = '+';
    if (str == NULL) return 0;                      // T6
    while (isspace(*str)) str++;                    // T14, T17, T18
    if (*str == '-' || *str == '+') { sign = *str; str++; }
    while (isdigit(*str)) {
        r *= 10;
        r += *str - '0';
        if (r > INT_MAX/10) { r = INT_MAX; break; }  // T10
            ++str;
    }
   if (sign == '-') r = -r;                        // T8
   return r;
}

char *
utoa(unsigned value, char *str, unsigned base)
{
    const char digits[] = "0123456789abcdefghijklmnopqrstuvwxyz";
    int i, j;
    unsigned remainder;
    char c;

    /* Check base is supported. */
    if ((base < 2) || (base > 36)) {
        str[0] = '\0';
        return NULL;
     }

    /* Convert to string. Digits are in reverse order.  */
    i = 0;
    do {
        remainder = value % base;
        str[i++] = digits[remainder];
        value = value / base;
    } while (value != 0);
    str[i] = '\0';

    /* Reverse string.  */
    for (j = 0, i--; j < i; j++, i--) {
        c = str[j];
        str[j] = str[i];
        str[i] = c;
    }

    return str;
}

char *
itoa(int value, char *str, int base)
{
    unsigned uvalue;
    int i = 0;

    /* Check base is supported. */
    if ((base < 2) || (base > 36)) {
        str[0] = '\0';
        return NULL;
    }

    /* Negative numbers are only supported for decimal.
     * Cast to unsigned to avoid overflow for maximum negative value.  */
    if ((base == 10) && (value < 0)) {
        str[i++] = '-';
        uvalue = (unsigned)-value;
    } else {
        uvalue = (unsigned)value;
    }

    utoa(uvalue, &str[i], base);
    return str;
}
