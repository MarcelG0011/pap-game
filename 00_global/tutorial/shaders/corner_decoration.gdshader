// res://ui/tutorial/shaders/corner_decoration.gdshader
// Desenha linhas em forma de canto (L) num Control node 20x20
// Parâmetros: cor da linha, largura

shader_type canvas_item;

uniform vec4  line_color  : source_color = vec4(0.392, 0.549, 0.863, 0.7);
uniform float line_width  : hint_range(1.0, 4.0) = 2.0;
uniform int   corner_type : hint_range(0, 3) = 0;
// 0 = top-left, 1 = top-right, 2 = bottom-left, 3 = bottom-right

void fragment() {
	vec2 uv     = UV;
	vec2 size   = 1.0 / TEXTURE_PIXEL_SIZE;
	vec2 pixel  = uv * size;
	float w     = line_width;
	
	bool on_line = false;
	
	if (corner_type == 0) {
		// Top-left: linha em cima e à esquerda
		on_line = (pixel.y < w) || (pixel.x < w);
	} else if (corner_type == 1) {
		// Top-right: linha em cima e à direita
		on_line = (pixel.y < w) || (pixel.x > size.x - w);
	} else if (corner_type == 2) {
		// Bottom-left: linha em baixo e à esquerda
		on_line = (pixel.y > size.y - w) || (pixel.x < w);
	} else {
		// Bottom-right: linha em baixo e à direita
		on_line = (pixel.y > size.y - w) || (pixel.x > size.x - w);
	}
	
	COLOR = on_line ? line_color : vec4(0.0);
}
