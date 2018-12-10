
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
