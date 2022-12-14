module game(
	input logic frame_clk, reset,
	input logic [15:0] keycode,
	output logic [9:0] character_pos_x,
	output logic [8:0] character_pos_y,
	output logic [10:0] screen_pos,
	output logic big, idle, walk1, walk2, walk3, jump, direction, lose, transition,
	output logic [35:0] coin,
	output logic [3:0] game_state,
	output logic [5:0] score
);
	
	logic [9:0] mario_x, motion_x, new_motion_x;
	logic [8:0] mario_y, motion_y, new_motion_y;
	logic [10:0] screen_x, motion_screen, new_motion_screen;
	logic [3:0] walk_counter, new_walk_counter;
	logic jump_state, new_jump_state, new_big;
	logic [5:0] trans_counter, new_trans_counter;
	logic [8:0] y_min, new_y_min, tube_height;
	logic [7:0] keycode0, keycode1; // two simultaneous keycodes supported
	logic [5:0] new_score;
	logic [35:0] new_coin;
	logic [6:0] temp; // temp=32 when big, 0 when small
	enum logic {RIGHT, LEFT} dir, new_direction;
	
	assign keycode0 = keycode[7:0];
	assign keycode1 = keycode[15:8];
	
	// parameters
	parameter [9:0] vx = 2;
	parameter [8:0] vy = -14;
	parameter [8:0] g = 1;
	parameter [10:0] x_min = 0;
	parameter [10:0] x_max = 1920;
	parameter [8:0] y_minimum = 320;
	parameter [10:0] screen_max = x_max - 640;
	
	// mario states
	enum logic [2:0] {Small, Transition, Big} curr_state, next_state;
	
	// game states
	enum logic [3:0] {state1, trans1, state2, over} curr_game_state, next_game_state;
	
	always_ff @ (posedge reset or posedge frame_clk) begin
		if (reset) begin
			mario_x <= 10'd220;
			mario_y <= y_minimum;
			curr_state <= Small;
			trans_counter <= 5'd0;
			dir <= RIGHT;
			screen_x <= 11'd0;
			score <= 6'd0;
			coin <= 36'hfffffffff;
			curr_game_state <= state1;
		end
		
		else begin
			mario_x <= mario_x + new_motion_x;
			mario_y <= mario_y + new_motion_y;
			screen_x <= screen_x + new_motion_screen;
			
			motion_x <= new_motion_x;
			motion_y <= new_motion_y;
			motion_screen <= new_motion_screen;
			
			dir <= new_direction;
			walk_counter <= new_walk_counter;
			
			jump_state <= new_jump_state;
			
			curr_state <= next_state;
			curr_game_state <= next_game_state;
			trans_counter <= new_trans_counter;
			
			y_min <= new_y_min;
			big <= new_big;
			
			score <= new_score;
			coin <= new_coin;
		end
	end

	
	always_comb begin
		// motionless when no keycode, motion_y calculated separately due to gravity
		new_motion_x = 0;
		new_motion_y = 0;
		new_motion_screen = 0;
		new_jump_state = 0;
		new_direction = dir;
		next_state = Small;
		new_trans_counter = 0;
		new_score = score;
		new_coin = coin;
		next_game_state = curr_game_state;
		tube_height = 0;
		temp = 0;
	
		if (keycode0 == 8'h04 || keycode1 == 8'h04) begin // A
			/* This is for not going back
			if (mario_x <= 0)
				new_motion_x = (~(mario_x) + 1'b1);
			else
				new_motion_x = (~(vx) + 1'b1);
			*/
			if (mario_x <= 170) begin
				if (screen_x > 0) begin
					new_motion_x = 0;
					new_motion_screen = ~(vx) + 1'b1;
				end
				else begin
					new_motion_screen = ~(screen_x) + 1'b1;
					new_motion_x = ~(vx) + 1'b1;
				end
			end
			else begin
				new_motion_x = ~(vx) + 1'b1;
			end
			if (mario_x <= 0) begin
				new_motion_x = ~(mario_x) + 1'b1;
				new_motion_screen = ~(screen_x) + 1'b1;
			end
			
			new_direction = LEFT;
			new_walk_counter = (walk_counter + 1);
		end
		else if (keycode0 == 8'h07 || keycode1 == 8'h07) begin // D
			if (mario_x >= 412) begin
				if (screen_x < screen_max) begin
					new_motion_x = 0;
					new_motion_screen = vx;
				end
				else begin
					new_motion_screen = screen_max - screen_x;
					new_motion_x = vx;
				end
			end
			else begin
				new_motion_x = vx;
			end
			if (mario_x >= 608) begin
				new_motion_x = 608 - mario_x;
				new_motion_screen = screen_max - screen_x;
			end		
			
			new_direction = RIGHT;
			new_walk_counter = (walk_counter + 1);
		end
		else
			new_walk_counter = 0;

		
		// jump and gravity
		if (jump_state) begin
			new_motion_y = motion_y + g;
			if (character_pos_y >= y_min) begin
				new_motion_y = y_min - character_pos_y;
			end
			else begin
				new_jump_state = 1'b1;
			end
		end
		else if (keycode0 == 8'h1A || keycode1 == 8'h1A) begin // W
			new_motion_y = vy;
			new_jump_state = 1'b1;
		end
		else if (character_pos_y >= y_min)
			new_motion_y = y_min - character_pos_y;
		
		// walk state calculation
		walk1 = 1'b0;
		walk2 = 1'b0;
		walk3 = 1'b0;
		if (walk_counter > 0 && walk_counter <= 5)
			walk1 = 1'b1;
		else if (walk_counter > 5 && walk_counter <= 10)
			walk2 = 1'b1;
		else if (walk_counter > 10 && walk_counter <= 15)
			walk3 = 1'b1;
			
		// variables calculation according to different game states
		unique case (curr_game_state)
			
			state1: begin
				// block collision detection
				if (screen_x + mario_x >= 868 && screen_x + mario_x <= 969) begin
					if (motion_y[8] == 1 && character_pos_y <= 242 && character_pos_y >= 232) begin
						new_motion_y = 0;
						if (screen_x + mario_x >= 906 && screen_x + mario_x <= 932) begin
							if (curr_state == Small) begin
								next_state = Transition;
								new_score = score + 6'd2;
							end
						end
					end
					else if (motion_y[8] == 0 && character_pos_y <= 198 && character_pos_y >= 178 && ~big) begin
						new_motion_y = 188 - character_pos_y;
						new_jump_state = 1'b0;
					end
				end
				else begin
					if (character_pos_y < y_min)
						new_jump_state = 1'b1;
				end
				
				// coin calculation
				if (screen_x + mario_x >= 368 && screen_x + mario_x <= 418 && coin[0] == 1'b1) begin
					if (character_pos_y >= 214 && character_pos_y <= 270) begin
						new_coin = coin & ~(36'b1);
						new_score = score + 1'b1;
					end
				end
				
				// tube calculation
				if (big)
					tube_height = 227;
				else
					tube_height = 259;
				if (screen_x + mario_x >= 1805 && screen_x + mario_x <= 1865) begin
					if (character_pos_y >= tube_height-10 && character_pos_y <= tube_height+10 && motion_y[8] == 0) begin
						new_motion_y = tube_height - character_pos_y;
						new_jump_state = 1'b0;
						if (keycode0 == 8'h16 || keycode1 == 8'h16) begin // S
							next_game_state = trans1;
						end
					end
				end
				else begin
					if (character_pos_y < y_min)
						new_jump_state = 1'b1;
				end
			end
			
			trans1: begin
				new_motion_x = 220 - mario_x;
				new_motion_screen = ~(screen_x) + 1'b1;
				new_jump_state = 1'b1;
				new_motion_y = ~(mario_y) + 1'b1 + y_min;
			end
			
			state2: begin
				// game over calculation
				if (screen_x + mario_x >= 1805 && mario_y > 250) begin
					next_game_state = over;
				end
				
				// coin calculation
				if (big)
					temp = 6'd32;
				else
					temp = 6'd0;
				// 3
				if (screen_x + mario_x >= 968 && screen_x + mario_x <= 1019) begin
					if (character_pos_y + temp >= 192 && character_pos_y + temp <= 248 && coin[1] == 1'b1) begin
						new_coin = coin & ~(36'b10);
						new_score = score + 1'b1;
					end
					else if (character_pos_y + temp >= 242 && character_pos_y + temp <= 298 && coin[2] == 1'b1) begin
						new_coin = coin & ~(36'b100);
						new_score = score + 1'b1;
					end
					else if (character_pos_y + temp >= 292 && character_pos_y + temp <= 348 && coin[3] == 1'b1) begin
						new_coin = coin & ~(36'b1000);
						new_score = score + 1'b1;
					end
				end
				if (screen_x + mario_x >= 998 && screen_x + mario_x <= 1049) begin
					if (character_pos_y + temp >= 192 && character_pos_y + temp <= 248 && coin[4] == 1'b1) begin
						new_coin = coin & ~(36'b10000);
						new_score = score + 1'b1;
					end
					else if (character_pos_y + temp >= 242 && character_pos_y + temp <= 298 && coin[5] == 1'b1) begin
						new_coin = coin & ~(36'b100000);
						new_score = score + 1'b1;
					end
					else if (character_pos_y + temp >= 292 && character_pos_y + temp <= 348 && coin[6] == 1'b1) begin
						new_coin = coin & ~(36'b1000000);
						new_score = score + 1'b1;
					end
				end
				if (screen_x + mario_x >= 1028 && screen_x + mario_x <= 1079) begin
					if (character_pos_y + temp >= 192 && character_pos_y + temp <= 248 && coin[7] == 1'b1) begin
						new_coin = coin & ~(36'b10000000);
						new_score = score + 1'b1;
					end
					else if (character_pos_y + temp >= 217 && character_pos_y + temp <= 273 && coin[8] == 1'b1) begin
						new_coin = coin & ~(36'b100000000);
						new_score = score + 1'b1;
					end
					else if (character_pos_y + temp >= 242 && character_pos_y + temp <= 298 && coin[9] == 1'b1) begin
						new_coin = coin & ~(36'b1000000000);
						new_score = score + 1'b1;
					end
					else if (character_pos_y + temp >= 267 && character_pos_y + temp <= 323 && coin[10] == 1'b1) begin
						new_coin = coin & ~(36'b10000000000);
						new_score = score + 1'b1;
					end
					else if (character_pos_y + temp >= 292 && character_pos_y + temp <= 348 && coin[11] == 1'b1) begin
						new_coin = coin & ~(36'b100000000000);
						new_score = score + 1'b1;
					end
				end
				// 8
				if (screen_x + mario_x >= 1058 && screen_x + mario_x <= 1109) begin
					if (character_pos_y + temp >= 192 && character_pos_y + temp <= 248 && coin[12] == 1'b1) begin
						new_coin = coin & ~(36'b1000000000000);
						new_score = score + 1'b1;
					end
					else if (character_pos_y + temp >= 217 && character_pos_y + temp <= 273 && coin[13] == 1'b1) begin
						new_coin = coin & ~(36'b10000000000000);
						new_score = score + 1'b1;
					end
					else if (character_pos_y + temp >= 242 && character_pos_y + temp <= 298 && coin[14] == 1'b1) begin
						new_coin = coin & ~(36'b100000000000000);
						new_score = score + 1'b1;
					end
					else if (character_pos_y + temp >= 267 && character_pos_y + temp <= 323 && coin[15] == 1'b1) begin
						new_coin = coin & ~(36'b1000000000000000);
						new_score = score + 1'b1;
					end
					else if (character_pos_y + temp >= 292 && character_pos_y + temp <= 348 && coin[16] == 1'b1) begin
						new_coin = coin & ~(36'b10000000000000000);
						new_score = score + 1'b1;
					end
				end
				if (screen_x + mario_x >= 1088 && screen_x + mario_x <= 1139) begin
					if (character_pos_y + temp >= 192 && character_pos_y + temp <= 248 && coin[17] == 1'b1) begin
						new_coin = coin & ~(36'b100000000000000000);
						new_score = score + 1'b1;
					end
					else if (character_pos_y + temp >= 242 && character_pos_y + temp <= 298 && coin[18] == 1'b1) begin
						new_coin = coin & ~(36'b1000000000000000000);
						new_score = score + 1'b1;
					end
					else if (character_pos_y + temp >= 292 && character_pos_y + temp <= 348 && coin[19] == 1'b1) begin
						new_coin = coin & ~(36'b10000000000000000000);
						new_score = score + 1'b1;
					end
				end
				if (screen_x + mario_x >= 1118 && screen_x + mario_x <= 1169) begin
					if (character_pos_y + temp >= 192 && character_pos_y + temp <= 248 && coin[20] == 1'b1) begin
						new_coin = coin & ~(36'b100000000000000000000);
						new_score = score + 1'b1;
					end
					else if (character_pos_y + temp >= 217 && character_pos_y + temp <= 273 && coin[21] == 1'b1) begin
						new_coin = coin & ~(36'b1000000000000000000000);
						new_score = score + 1'b1;
					end
					else if (character_pos_y + temp >= 242 && character_pos_y + temp <= 298 && coin[22] == 1'b1) begin
						new_coin = coin & ~(36'b10000000000000000000000);
						new_score = score + 1'b1;
					end
					else if (character_pos_y + temp >= 267 && character_pos_y + temp <= 323 && coin[23] == 1'b1) begin
						new_coin = coin & ~(36'b100000000000000000000000);
						new_score = score + 1'b1;
					end
					else if (character_pos_y + temp >= 292 && character_pos_y + temp <= 348 && coin[24] == 1'b1) begin
						new_coin = coin & ~(36'b1000000000000000000000000);
						new_score = score + 1'b1;
					end
				end
				// 5
				if (screen_x + mario_x >= 1148 && screen_x + mario_x <= 1199) begin
					if (character_pos_y + temp >= 192 && character_pos_y + temp <= 248 && coin[25] == 1'b1) begin
						new_coin = coin & ~(36'b10000000000000000000000000);
						new_score = score + 1'b1;
					end
					else if (character_pos_y + temp >= 217 && character_pos_y + temp <= 273 && coin[26] == 1'b1) begin
						new_coin = coin & ~(36'b100000000000000000000000000);
						new_score = score + 1'b1;
					end
					else if (character_pos_y + temp >= 242 && character_pos_y + temp <= 298 && coin[27] == 1'b1) begin
						new_coin = coin & ~(36'b1000000000000000000000000000);
						new_score = score + 1'b1;
					end
					else if (character_pos_y + temp >= 292 && character_pos_y + temp <= 348 && coin[28] == 1'b1) begin
						new_coin = coin & ~(36'b10000000000000000000000000000);
						new_score = score + 1'b1;
					end
				end
				if (screen_x + mario_x >= 1178 && screen_x + mario_x <= 1229) begin
					if (character_pos_y + temp >= 192 && character_pos_y + temp <= 248 && coin[29] == 1'b1) begin
						new_coin = coin & ~(36'b100000000000000000000000000000);
						new_score = score + 1'b1;
					end
					else if (character_pos_y + temp >= 242 && character_pos_y + temp <= 298 && coin[30] == 1'b1) begin
						new_coin = coin & ~(36'b1000000000000000000000000000000);
						new_score = score + 1'b1;
					end
					else if (character_pos_y + temp >= 292 && character_pos_y + temp <= 348 && coin[31] == 1'b1) begin
						new_coin = coin & ~(36'b10000000000000000000000000000000);
						new_score = score + 1'b1;
					end
				end
				if (screen_x + mario_x >= 1208 && screen_x + mario_x <= 1259) begin
					if (character_pos_y + temp >= 192 && character_pos_y + temp <= 248 && coin[32] == 1'b1) begin
						new_coin = coin & ~(36'b100000000000000000000000000000000);
						new_score = score + 1'b1;
					end
					else if (character_pos_y + temp >= 242 && character_pos_y + temp <= 298 && coin[33] == 1'b1) begin
						new_coin = coin & ~(36'b1000000000000000000000000000000000);
						new_score = score + 1'b1;
					end
					else if (character_pos_y + temp >= 267 && character_pos_y + temp <= 323 && coin[34] == 1'b1) begin
						new_coin = coin & ~(36'b10000000000000000000000000000000000);
						new_score = score + 1'b1;
					end
					else if (character_pos_y + temp >= 292 && character_pos_y + temp <= 348 && coin[35] == 1'b1) begin
						new_coin = coin & ~(36'b100000000000000000000000000000000000);
						new_score = score + 1'b1;
					end
				end
			end
			
			over: begin
				new_motion_x = 0;
				new_motion_y = 0;
				new_motion_screen = 0;
				new_walk_counter = 0;
				new_direction = RIGHT;
				new_jump_state = 0;
			end
			
			default:;
			
		endcase
		
		// next mario state calculation
		unique case (curr_state)

			Transition: begin
				if (trans_counter == 6'd63) begin
					next_state = Big;
					new_trans_counter = 0;
				end
				else begin
					next_state = Transition;
					new_trans_counter = trans_counter + 1'b1;
				end
			end
			
			Big: begin
				next_state = Big;
			end
			
			default:
				;
			
		endcase
		
		// next game state calculation
		unique case (curr_game_state)
			
			trans1: begin
				next_game_state = state2;
			end
			
			default:;
			
		endcase
	end
	
	
	// output control signals calculation
	always_comb begin
		unique case (curr_state)
			
			Small: begin
				new_big = 1'b0;
				transition = 1'b0;
			end
			
			Transition: begin
				transition = 1'b1;
				if (trans_counter >= 0 && trans_counter <= 7)
					new_big = 1'b0;
				else if (trans_counter >= 8 && trans_counter <= 15)
					new_big = 1'b1;
				else if (trans_counter >= 16 && trans_counter <= 23)
					new_big = 1'b0;
				else if (trans_counter >= 24 && trans_counter <= 31)
					new_big = 1'b1;
				else if (trans_counter >= 32 && trans_counter <= 39)
					new_big = 1'b0;
				else if (trans_counter >= 40 && trans_counter <= 47)
					new_big = 1'b1;
				else if (trans_counter >= 48 && trans_counter <= 55)
					new_big = 1'b0;
				else
					new_big = 1'b1;
			end
			
			Big: begin
				new_big = 1'b1;
				transition = 1'b1;
			end
			
		endcase
		
		if (transition == 1'b1)
			new_y_min = y_minimum - 9'd32;
		else
			new_y_min = y_minimum;
	end
	
	assign character_pos_y = mario_y;
	assign character_pos_x = mario_x;
	assign screen_pos = screen_x;
	assign jump = jump_state;
	assign idle = ~(walk1 | walk2 | walk3 | jump);
	assign direction = dir;
	assign game_state = curr_game_state;

endmodule
