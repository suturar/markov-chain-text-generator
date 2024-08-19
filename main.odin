package mct

import "core:fmt"
import "core:os"
import "core:strings"
import "core:unicode/utf8"
import "core:unicode"
import "core:slice"
import "core:math/rand"

Token :: distinct string
token_transitions : map[Token]List
List :: distinct map[Token]f32

Lexer :: struct {
    index: int,
    data: []rune,
}
lex: Lexer
lexer_next :: proc() -> (string, bool) {
    lexer_skip_non_alpha()
    if lexer_is_eof() do return {}, false
    starting_pos := lex.index
    is_valid :: proc(c: rune) -> bool {
	return unicode.is_alpha(c) || c == '.' || c == ','
    }
    for !lexer_is_eof() && is_valid(lex.data[lex.index]) {
	lex.index += 1
    }
    word := lex.data[starting_pos:lex.index]
    
    return utf8.runes_to_string(word, context.temp_allocator), true
}
lexer_skip_non_alpha :: proc() {
    for !lexer_is_eof() && !unicode.is_alpha(lex.data[lex.index]) {
	lex.index += 1
    }
}
lexer_is_eof :: proc() -> bool
{
    return lex.index >= len(lex.data)
}

main :: proc() {
    file, ok := os.read_entire_file("el-quijote.txt")
    defer delete(file)
    if !ok {
	fmt.eprintln("Couldn't open file")
	os.exit(1)
    }
    /* lc_file := strings.to_lower(string(file)) */
    /* defer delete(lc_file) */
    
    runes := utf8.string_to_runes(string(file))
    defer delete(runes)

    token_list : [dynamic]Token
    defer delete(token_list)
    lex.data = runes
    for word in lexer_next() do append(&token_list, Token(word))
    for tok in token_list {
	token_transitions[tok] = {}
    }

    for tok, i in token_list[0:(len(token_list) - 1)] {
	list := &token_transitions[tok]
	list[token_list[i + 1]] += 1
    }
    for _, &list in token_transitions {
	norm : f32
	for _, freq in list {
	    norm += freq
	}
	for _, &freq in list {
	    freq /= norm
	}

    }

    for i in 0..<10 do generate_text("Sancho", token_transitions, 30)
    //// Cleanup
    for tok, list in token_transitions do delete(list)
    delete (token_transitions)
}

generate_text :: proc(first_token: Token, token_transitions: map[Token]List , size: int) {
    if first_token not_in token_transitions {
	fmt.printfln("'%v' no se encuentra en el corpus proporcionado.", first_token)
	os.exit(1)
    }
    current_token := first_token
    fmt.printf("%s ", current_token)
    for i in 0..<size {
	current_token = get_next_token(token_transitions[current_token])
	fmt.printf("%s ", current_token) 
    }
    fmt.println()
    
}

get_next_token :: proc(list: List) -> Token {
    r := rand.float32()

    for tok, freq in list {
	r -= freq
	if r < 0 do return tok
    }
    unreachable()
}
