module color_mapper(
		input logic Clk,// vblank, hblank,
		input logic [8:0] drawY,
		input logic [9:0] character_pos_x,
		input logic [8:0] character_pos_y,
		input logic [10:0] screen_pos,
		input logic idle, walk1, walk2, walk3, jump, direction, big, lose, transition,
		input logic [35:0] coin,
		input logic [3:0] game_state,
		input logic [5:0] score,
		output logic [3:0] color,
		output logic [18:0] addr,
		output logic we
);
	parameter [9:0] tree_distance = 288;
	parameter [9:0] score_offset = 34; // current best: 34
	
	// Use dir for direction (LEFT/RIGHT)
	enum logic {LEFT, RIGHT} dir;
	always_comb begin
		if (direction == 1'b1)
			dir = LEFT;
		else
			dir = RIGHT;
	end
	
	// drawing state machine
	enum logic [3:0] {waiting, drawBG, drawBG2, drawMario} curr_state, next_state;
	logic [19:0] count, new_count; // counter for each state
	
	always_ff @ (posedge Clk) begin
		curr_state <= next_state;
		count <= new_count;
	end
	
	always_comb begin
		unique case (curr_state)
			drawBG: begin
				if (count < 640*480 - 1) begin
					next_state = drawBG;
					new_count = count + 1;
				end
				else begin
					next_state = drawMario;
					new_count = 0;
				end
			end
			
			drawBG2: begin
				if (count < 640*480 - 1) begin
					next_state = drawBG2;
					new_count = count + 1;
				end
				else begin
					next_state = drawMario;
					new_count = 0;
				end
			end
			
			drawMario: begin
				// small: walk1, jump 32*32, lose 28*28, rest 24*32
				// big: all 32*64
				if (big) begin
					if (count < 32*64 - 1) begin
						next_state = drawMario;
						new_count = count + 1;
					end
					else begin
						next_state = waiting;
						new_count = 0;
					end
				end
				else begin
					if (walk1 | jump) begin
						if (count < 32*32 - 1) begin
							next_state = drawMario;
							new_count = count + 1;
						end
						else begin
							next_state = waiting;
							new_count = 0;
						end
					end
					else if (lose) begin
						if (count < 28*28 - 1) begin
							next_state = drawMario;
							new_count = count + 1;
						end
						else begin
							next_state = waiting;
							new_count = 0;
						end
					end
					else begin
						if (count < 24*32 - 1) begin
							next_state = drawMario;
							new_count = count + 1;
						end
						else begin
							next_state = waiting;
							new_count = 0;
						end
					end
				end
			end
			
			waiting: begin
				// RAM is 2.5 times faster than VGA read
				// 480 - 480/2.5 = 288
				if (drawY < 9'd288) begin
					next_state = waiting;
					new_count = 0;
				end
				else begin
					if (game_state == 4'h0)
						next_state = drawBG;
					else
						next_state = drawBG2;
					new_count = 0;
				end
			end
			
			default: begin
				next_state = waiting;
				new_count = 0;
			end
			
		endcase
	end
	
	logic [18:0] write_addr;
	logic write_ena;
	
	// declare sprite roms
	logic [3:0] bg_color, tree_color, cloud_color, bullet_color,
					tube_color, turtle1_color, ground_color, ground2_color,
					block1_color, block2_color, block3_color,
					mario_small_idle_color, mario_small_jump_color,
					mario_small_walk1_color, mario_small_walk2_color,
					mario_small_walk3_color, mario_small_lose_color,
					mario_big_idle_color, mario_big_jump_color,
					mario_big_walk1_color, mario_big_walk2_color,
					mario_big_walk3_color, coin_color, flag_color, prof_color;
					
	//bg_rom bg_rom0(.read_address(count), .Clk(Clk), .data_Out(bg_color));
	mario_small_idle_rom mario_small_idle_rom0(
		.read_address(count+1), .Clk(Clk), .data_Out(mario_small_idle_color));
	mario_small_jump_rom mario_small_jump_rom0(
		.read_address(count+1), .Clk(Clk), .data_Out(mario_small_jump_color));
	mario_small_walk1_rom mario_small_walk1_rom0(
		.read_address(count+1), .Clk(Clk), .data_Out(mario_small_walk1_color));
	mario_small_walk2_rom mario_small_walk2_rom0(
		.read_address(count+1), .Clk(Clk), .data_Out(mario_small_walk2_color));
	mario_small_walk3_rom mario_small_walk3_rom0(
		.read_address(count+1), .Clk(Clk), .data_Out(mario_small_walk3_color));
	mario_big_idle_rom mariO_big_idle_rom0(
		.read_address(count+1), .Clk(Clk), .data_Out(mario_big_idle_color));
	mario_big_jump_rom mario_big_jump_rom0(
		.read_address(count+1), .Clk(Clk), .data_Out(mario_big_jump_color));
	mario_big_walk1_rom mario_big_walk1_rom0(
		.read_address(count+1), .Clk(Clk), .data_Out(mario_big_walk1_color));
	mario_big_walk2_rom mario_big_walk2_rom0(
		.read_address(count+1), .Clk(Clk), .data_Out(mario_big_walk2_color));
	mario_big_walk3_rom mario_big_walk3_rom0(
		.read_address(count+1), .Clk(Clk), .data_Out(mario_big_walk3_color));
	cloud_rom cloud_rom0(
		.read_address((cloud_read_addr+1)%9088), .Clk(Clk), .data_Out(cloud_color)); // rom of cloud
	ground_block_rom ground_block_rom0(
		.read_address(block_addr+1), .Clk(Clk), .data_Out(ground_color));
	//ground_block2_rom ground_block2_rom0(
	//	.read_address(block_addr+1), .Clk(Clk), .data_Out(ground2_color));
	block2_rom block2_rom0(
		.read_address((block2_addr+1)%506), .Clk(Clk), .data_Out(block2_color));
	block3_rom block3_rom0(
		.read_address((block3_addr+1)%506), .Clk(Clk), .data_Out(block3_color));
	tree_rom tree_rom0(                                                    //rom of tree
		.read_address((tree_read_addr+1)%5986), .Clk(Clk), .data_Out(tree_color));
	font_rom font_rom0(
		.addr(new_font_addr+1), .data(font_data));
	coin_rom coin_rom0(
		.read_address(coin_addr), .Clk(Clk), .data_Out(coin_color));
	tube_rom tube_rom0(
		.read_address(tube_addr), .Clk(Clk), .data_Out(tube_color));
	flag_rom flag_rom0(
		.read_address(flag_addr), .Clk(Clk), .data_Out(flag_color));
	prof_rom prof_rom0(
		.read_address(prof_addr), .Clk(Clk), .data_Out(prof_color));
	
	logic [4:0] temp; // this is used in write_addr calculation
	logic [13:0] cloud_read_addr;   //in order to not mess up with the count, this is used
	logic [13:0] new_cloud_addr;    //new_cloud_addr
	logic [11:0] block_addr;
	logic [11:0] new_block_addr;
	logic [8:0] block2_addr, new_block2_addr;
	logic [8:0] block3_addr, new_block3_addr;
	logic [12:0] tree_read_addr;    //tree's address
	logic [12:0] new_tree_addr;
	logic [10:0] new_font_addr;
	logic [7:0] font_data, new_font_data;
	logic [8:0] coin_addr, new_coin_addr;
	logic [11:0] tube_addr, new_tube_addr;
	logic [12:0] flag_addr, new_flag_addr;
	logic [13:0] prof_addr, new_prof_addr;
	
	always_ff @ (posedge Clk) begin
		cloud_read_addr <= new_cloud_addr;    //update addr every clk cycle
		block_addr <= new_block_addr;
		block2_addr <= new_block2_addr;
		block3_addr <= new_block3_addr;
		tree_read_addr <= new_tree_addr;      //update tree address
		coin_addr <= new_coin_addr;
		tube_addr <= new_tube_addr;
		flag_addr <= new_flag_addr;
		prof_addr <= new_prof_addr;
	end
	
	always_comb begin
		new_cloud_addr = 14'd0;
		new_block_addr = 12'd0;
		new_block2_addr = 9'd0;
		new_block3_addr = 9'd0;
		new_tree_addr = 13'd0;
		new_font_addr = 11'd0;
		new_coin_addr = 9'd0;
		new_tube_addr = 12'd0;
		new_flag_addr = 13'd0;
		new_prof_addr = 14'd0;
		
		if (game_state == 4'h0) begin
			// cloud address calculation
			if((screen_pos + count % 640 >= 500) && (screen_pos + count % 640 < 628)) begin     //get read_address 
				if(count/640 >= 100 && count/640 < 171 ) begin
					new_cloud_addr = screen_pos + count % 640 - 500 + (count/640 - 100) * 128;  //calculate the read address
				end
			end
			else if(screen_pos + count % 640 >= 900 && screen_pos + count % 640 < 1028) begin     //cloud at 900, 50
				if(count/640 >= 50 && count/640 < 121 ) begin
					new_cloud_addr = screen_pos + count % 640 - 900 + (count/640 - 50) * 128;
				end
			end
			else if(screen_pos + count % 640 >= 1500 && screen_pos + count % 640 < 1628) begin     //cloud at 900, 50
				if(count/640 >= 100 && count/640 < 171 ) begin
					new_cloud_addr = screen_pos + count % 640 - 1500 + (count/640 - 100) * 128;
				end
			end
			
			// block2 address calculation
			if (screen_pos + count % 640 >= 923 && screen_pos + count % 640 < 946) begin
				if (count/640 >= 220 && count/640 < 242) begin
					new_block2_addr = screen_pos + count % 640 - 923 + (count/640 - 220) * 23;
				end
			end
			
			// block3 address calculation
			if (screen_pos + count % 640 >= 900 && screen_pos + count % 640 < 923) begin
				if (count/640 >= 220 && count/640 < 242) begin
					new_block3_addr = screen_pos + count % 640 - 900 + (count/640 - 220) * 23;
				end
			end
			else if (screen_pos + count % 640 >= 946 && screen_pos + count % 640 < 969) begin
				if (count/640 >= 220 && count/640 < 242) begin
					new_block3_addr = screen_pos + count % 640 - 946 + (count/640 - 220) * 23;
				end
			end
			else if (screen_pos + count % 640 >= 923 && screen_pos + count % 640 < 946) begin
				if (count/640 >= 220 && count/640 < 242) begin
					new_block3_addr = screen_pos + count % 640 - 923 + (count/640 - 220) * 23;
				end
			end
			
			// tree address calculation
			if((screen_pos + count % 640) % tree_distance >= 0 && (screen_pos + count % 640) % tree_distance < 73) begin     //tree every 480 pixel
				if(count/640 >= 275 && count/640 < 357 ) begin
					new_tree_addr = (screen_pos + count % 640) % tree_distance + 73 * (count/640 - 275); 
				end
			end
			
			// coin address calculation
			if (screen_pos + count % 640 >= 400 && screen_pos + count % 640 <= 418) begin
				if (count/640 >= 246 && count/640 <= 270) begin
					new_coin_addr = screen_pos + count % 640 - 400 + (count/640 - 246) * 18;
				end
			end
			
			// tube address calculation
			if (screen_pos + count % 640 >= 1820 && screen_pos + count % 640 <= 1877) begin
				if (count/640 >= 291 && count/640 <= 352) begin
					new_tube_addr = screen_pos + count % 640 - 1820 + (count/640 - 291) * 57;
				end
			end
		end
		
		else begin
			// flag address calculation
			if (screen_pos + count % 640 >= 1800 && screen_pos + count % 640 <= 1861) begin
				if (count/640 >= 272 && count/640 <= 352) begin
					new_flag_addr = screen_pos + count % 640 - 1800 + (count/640 - 272) * 60;
				end
			end
			
			// prof address calculation
			if (screen_pos + count % 640 >= 1100 && screen_pos + count % 640 <= 1220) begin
				if (count/640 >= 80 && count/640 <= 180) begin
					new_prof_addr = screen_pos + count % 640 - 1100 + (count/640 - 80) * 120;
				end
			end
			
			// game over message calculation
			if (count % 640 >= 288 && count % 640 < 296) begin //Y
				if (count/640 >= 160 && count/640 < 176) begin
					new_font_addr = (11'h59 << 4) + (count/640 - 160);
				end
			end
			else if (count % 640 >= 296 && count % 640 < 304) begin //O
				if (count/640 >= 160 && count/640 < 176) begin
					new_font_addr = (11'h4f << 4) + (count/640 - 160);
				end
			end
			else if (count % 640 >= 304 && count % 640 < 312) begin //U
				if (count/640 >= 160 && count/640 < 176) begin
					new_font_addr = (11'h55 << 4) + (count/640 - 160);
				end
			end
			else if (count % 640 >= 312 && count % 640 < 320) begin // 
				if (count/640 >= 160 && count/640 < 176) begin
					new_font_addr = (11'h00 << 4) + (count/640 - 160);
				end
			end
			else if (count % 640 >= 320 && count % 640 < 328) begin //W
				if (count/640 >= 160 && count/640 < 176) begin
					new_font_addr = (11'h57 << 4) + (count/640 - 160);
				end
			end
			else if (count % 640 >= 328 && count % 640 < 336) begin //I
				if (count/640 >= 160 && count/640 < 176) begin
					new_font_addr = (11'h49 << 4) + (count/640 - 160);
				end
			end
			else if (count % 640 >= 336 && count % 640 < 344) begin //N
				if (count/640 >= 160 && count/640 < 176) begin
					new_font_addr = (11'h4e << 4) + (count/640 - 160);
				end
			end
			else if (count % 640 >= 344 && count % 640 < 352) begin //!
				if (count/640 >= 160 && count/640 < 176) begin
					new_font_addr = (11'h21 << 4) + (count/640 - 160);
				end
			end
			
			// coins address calculation
			// 3
			if (screen_pos + count % 640 >= 1000 && screen_pos + count % 640 < 1019) begin
				if (count/640 >= 224 && count/640 <= 248) begin
					new_coin_addr = screen_pos + count % 640 - 1000 + (count/640 - 224) * 18;
				end
				else if (count/640 >= 274 && count/640 <= 298) begin
					new_coin_addr = screen_pos + count % 640 - 1000 + (count/640 - 274) * 18;
				end
				else if (count/640 >= 324 && count/640 <= 348) begin
					new_coin_addr = screen_pos + count % 640 - 1000 + (count/640 - 324) * 18;
				end
			end
			else if (screen_pos + count % 640 >= 1030 && screen_pos + count % 640 < 1049) begin
				if (count/640 >= 224 && count/640 <= 248) begin
					new_coin_addr = screen_pos + count % 640 - 1030 + (count/640 - 224) * 18;
				end
				else if (count/640 >= 274 && count/640 <= 298) begin
					new_coin_addr = screen_pos + count % 640 - 1030 + (count/640 - 274) * 18;
				end
				else if (count/640 >= 324 && count/640 <= 348) begin
					new_coin_addr = screen_pos + count % 640 - 1030 + (count/640 - 324) * 18;
				end
			end
			else if (screen_pos + count % 640 >= 1060 && screen_pos + count % 640 < 1079) begin
				if (count/640 >= 224 && count/640 <= 248) begin
					new_coin_addr = screen_pos + count % 640 - 1060 + (count/640 - 224) * 18;
				end
				else if (count/640 >= 249 && count/640 <= 273) begin
					new_coin_addr = screen_pos + count % 640 - 1060 + (count/640 - 249) * 18;
				end
				else if (count/640 >= 274 && count/640 <= 298) begin
					new_coin_addr = screen_pos + count % 640 - 1060 + (count/640 - 274) * 18;
				end
				else if (count/640 >= 299 && count/640 <= 323) begin
					new_coin_addr = screen_pos + count % 640 - 1060 + (count/640 - 299) * 18;
				end
				else if (count/640 >= 324 && count/640 <= 348) begin
					new_coin_addr = screen_pos + count % 640 - 1060 + (count/640 - 324) * 18;
				end
			end
			
			//8
			else if (screen_pos + count % 640 >= 1090 && screen_pos + count % 640 < 1109) begin
				if (count/640 >= 224 && count/640 <= 248) begin
					new_coin_addr = screen_pos + count % 640 - 1090 + (count/640 - 224) * 18;
				end
				else if (count/640 >= 249 && count/640 <= 273) begin
					new_coin_addr = screen_pos + count % 640 - 1090 + (count/640 - 249) * 18;
				end
				else if (count/640 >= 274 && count/640 <= 298) begin
					new_coin_addr = screen_pos + count % 640 - 1090 + (count/640 - 274) * 18;
				end
				else if (count/640 >= 299 && count/640 <= 323) begin
					new_coin_addr = screen_pos + count % 640 - 1090 + (count/640 - 299) * 18;
				end
				else if (count/640 >= 324 && count/640 <= 348) begin
					new_coin_addr = screen_pos + count % 640 - 1090 + (count/640 - 324) * 18;
				end
			end
			else if (screen_pos + count % 640 >= 1120 && screen_pos + count % 640 < 1139) begin
				if (count/640 >= 224 && count/640 <= 248) begin
					new_coin_addr = screen_pos + count % 640 - 1120 + (count/640 - 224) * 18;
				end
				else if (count/640 >= 274 && count/640 <= 298) begin
					new_coin_addr = screen_pos + count % 640 - 1120 + (count/640 - 274) * 18;
				end
				else if (count/640 >= 324 && count/640 <= 348) begin
					new_coin_addr = screen_pos + count % 640 - 1120 + (count/640 - 324) * 18;
				end
			end
			else if (screen_pos + count % 640 >= 1150 && screen_pos + count % 640 < 1169) begin
				if (count/640 >= 224 && count/640 <= 248) begin
					new_coin_addr = screen_pos + count % 640 - 1150 + (count/640 - 224) * 18;
				end
				else if (count/640 >= 249 && count/640 <= 273) begin
					new_coin_addr = screen_pos + count % 640 - 1150 + (count/640 - 249) * 18;
				end
				else if (count/640 >= 274 && count/640 <= 298) begin
					new_coin_addr = screen_pos + count % 640 - 1150 + (count/640 - 274) * 18;
				end
				else if (count/640 >= 299 && count/640 <= 323) begin
					new_coin_addr = screen_pos + count % 640 - 1150 + (count/640 - 299) * 18;
				end
				else if (count/640 >= 324 && count/640 <= 348) begin
					new_coin_addr = screen_pos + count % 640 - 1150 + (count/640 - 324) * 18;
				end
			end
			
			//5
			else if (screen_pos + count % 640 >= 1180 && screen_pos + count % 640 < 1199) begin
				if (count/640 >= 224 && count/640 <= 248) begin
					new_coin_addr = screen_pos + count % 640 - 1180 + (count/640 - 224) * 18;
				end
				else if (count/640 >= 249 && count/640 <= 273) begin
					new_coin_addr = screen_pos + count % 640 - 1180 + (count/640 - 249) * 18;
				end
				else if (count/640 >= 274 && count/640 <= 298) begin
					new_coin_addr = screen_pos + count % 640 - 1180 + (count/640 - 274) * 18;
				end
				else if (count/640 >= 324 && count/640 <= 348) begin
					new_coin_addr = screen_pos + count % 640 - 1180 + (count/640 - 324) * 18;
				end
			end
			else if (screen_pos + count % 640 >= 1210 && screen_pos + count % 640 < 1229) begin
				if (count/640 >= 224 && count/640 <= 248) begin
					new_coin_addr = screen_pos + count % 640 - 1210 + (count/640 - 224) * 18;
				end
				else if (count/640 >= 274 && count/640 <= 298) begin
					new_coin_addr = screen_pos + count % 640 - 1210 + (count/640 - 274) * 18;
				end
				else if (count/640 >= 324 && count/640 <= 348) begin
					new_coin_addr = screen_pos + count % 640 - 1210 + (count/640 - 324) * 18;
				end
			end
			else if (screen_pos + count % 640 >= 1240 && screen_pos + count % 640 < 1259) begin
				if (count/640 >= 224 && count/640 <= 248) begin
					new_coin_addr = screen_pos + count % 640 - 1240 + (count/640 - 224) * 18;
				end
				else if (count/640 >= 274 && count/640 <= 298) begin
					new_coin_addr = screen_pos + count % 640 - 1240 + (count/640 - 274) * 18;
				end
				else if (count/640 >= 299 && count/640 <= 323) begin
					new_coin_addr = screen_pos + count % 640 - 1240 + (count/640 - 299) * 18;
				end
				else if (count/640 >= 324 && count/640 <= 348) begin
					new_coin_addr = screen_pos + count % 640 - 1240 + (count/640 - 324) * 18;
				end
			end
			
		end
		
		// score address calculation
		if (count % 640 >= 198+score_offset && count % 640 < 206+score_offset) begin //x
			if (count/640 >= 6 && count/640 < 22) begin
				new_font_addr = ((11'h30 + score/10) << 4) + (count/640 - 6);
			end
		end
		else if (count % 640 >= 206+score_offset && count % 640 < 214+score_offset) begin //x
			if (count/640 >= 6 && count/640 < 22) begin
				new_font_addr = ((11'h30 + score%10) << 4) + (count/640 - 6);
			end
		end
		else if (count % 640 >= 214+score_offset && count % 640 < 222+score_offset) begin //0
			if (count/640 >= 6 && count/640 < 22) begin
				new_font_addr = (11'h30 << 4) + (count/640 - 6);
			end
		end
		
		// ground block address calculation			
		if(count/640>= 352) begin
			new_block_addr = ((count/640 - 352) % 64) * 64 + (count % 640 + screen_pos) % 64; 
		end		
	end
	
	
	always_comb begin
		write_ena = 1'b1; // write enable default to high
		write_addr = 19'h0;
		color = 4'hA;
		temp = 5'b0;
		unique case (curr_state)
		
			waiting:
				write_ena = 1'b0;
				
			drawBG: begin
				write_addr = count;
				// color = bg_color;				
				if (count < 640*352) begin              //let's put a cloud at 500, 100 first; 900, 50; 1500, 125
					if(screen_pos + count % 640 >= 500 && screen_pos + count % 640 < 628) begin     //get the position of the cloud
						if(count/640 >= 100 && count/640 < 171 ) begin
							if (cloud_color == 4'h0)
								color = 4'hA;
							else
								color = cloud_color;
						end
					end

					else if(screen_pos + count % 640 >= 900 && screen_pos + count % 640 < 1028) begin     //cloud at 900, 50
						if(count/640 >= 50 && count/640 < 121 ) begin
							if (cloud_color == 4'h0)
								color = 4'hA;
							else
								color = cloud_color;
						end
					end

					else if(screen_pos + count % 640 >= 1500 && screen_pos + count % 640 < 1628) begin     //cloud at 1500, 170
						if(count/640 >= 100 && count/640 < 171 ) begin
							if (cloud_color == 4'h0)
								color = 4'hA;
							else
								color = cloud_color;
						end
					end
					
					// draw coin
					else if (screen_pos + count % 640 >= 400 && screen_pos + count % 640 <= 418) begin
						if (count/640 >= 246 && count/640 <= 270) begin
							if (coin_color == 4'h0 || coin[0] == 1'b0)
								color = 4'hA;
							else
								color = coin_color;
						end
					end
					
					// block2 & block3
					if(screen_pos + count % 640 >= 923 && screen_pos + count % 640 < 946) begin
						if (count/640 >= 220 && count/640 < 242) begin
							if (transition)
								color = block3_color;
							else
								color = block2_color;
						end
					end
					
					else if(screen_pos + count % 640 >= 900 && screen_pos + count % 640 < 923) begin
						if (count/640 >= 220 && count/640 < 242) begin
							color = block3_color;
						end
					end
					
					else if(screen_pos + count % 640 >= 946 && screen_pos + count % 640 < 969) begin
						if (count/640 >= 220 && count/640 < 242) begin
							color = block3_color;
						end
					end

					
					//draw trees
					if((screen_pos + count % 640) % tree_distance >= 0 && (screen_pos + count % 640) % tree_distance < 73) begin
						if(count/640 >= 275 && count/640 < 357 ) begin
							if (tree_color == 4'h0)
								color = 4'hA;
							else
								color = tree_color;
						end
					end
					
					// draw score
					if (count % 640 >= 198+score_offset && count % 640 < 206+score_offset) begin //x
						if (count/640 >= 6 && count/640 < 22) begin
							if (font_data[7 - ((count % 640) - 198-score_offset)] == 1)
								color = 4'h7;
							else
								color = 4'hA;
						end
					end
					else if (count % 640 >= 206+score_offset && count % 640 < 214+score_offset) begin //0
						if (count/640 >= 6 && count/640 < 22) begin
							if (font_data[7 - ((count % 640) - 206-score_offset)] == 1)
								color = 4'h7;
							else
								color = 4'hA;
						end
					end
					else if (count % 640 >= 214+score_offset && count % 640 < 222+score_offset) begin //0
						if (count/640 >= 6 && count/640 < 22) begin
							if (font_data[7 - ((count % 640) - 214-score_offset)] == 1)
								color = 4'h7;
							else
								color = 4'hA;
						end
					end
					
					// draw tube
					if (screen_pos + count % 640 > 1822 && screen_pos + count % 640 < 1877) begin
						if (count/640 >= 291 && count/640 < 352) begin
							if (tube_color == 4'h0)
								color = 4'hA;
							else
								color = tube_color;
						end
					end
					
				end
				else begin                //draw ground
					color = ground_color;
				end
			end
			
			drawBG2: begin
				write_addr = count;
				
				if (count < 640*352) begin
					color = 4'h3;
					
					// draw score
					if (count % 640 >= 198+score_offset && count % 640 < 206+score_offset) begin //x
						if (count/640 >= 6 && count/640 < 22) begin
							if (font_data[7 - ((count % 640) - 198-score_offset)] == 1)
								color = 4'hD;
							else
								color = 4'h3;
						end
					end
					else if (count % 640 >= 206+score_offset && count % 640 < 214+score_offset) begin //0
						if (count/640 >= 6 && count/640 < 22) begin
							if (font_data[7 - ((count % 640) - 206-score_offset)] == 1)
								color = 4'hD;
							else
								color = 4'h3;
						end
					end
					else if (count % 640 >= 214+score_offset && count % 640 < 222+score_offset) begin //0
						if (count/640 >= 6 && count/640 < 22) begin
							if (font_data[7 - ((count % 640) - 214-score_offset)] == 1)
								color = 4'hD;
							else
								color = 4'h3;
						end
					end
					
					// draw flag
					if (screen_pos + count % 640 >= 1800 && screen_pos + count % 640 <= 1861) begin
						if (count/640 >= 272 && count/640 <= 352) begin
							if (flag_color == 4'h0)
								color = 4'h3;
							else
								color = flag_color;
						end
					end

					// game over message
					if (game_state == 4'h3) begin
						if (count % 640 >= 288 && count % 640 < 296) begin //Y
							if (count/640 >= 160 && count/640 < 176) begin
								if (font_data[7 - ((count % 640) - 288)] == 1)
									color = 4'hD;
								else
									color = 4'h3;
							end
						end
						else if (count % 640 >= 296 && count % 640 < 304) begin //O
							if (count/640 >= 160 && count/640 < 176) begin
								if (font_data[7 - ((count % 640) - 296)] == 1)
									color = 4'hD;
								else
									color = 4'h3;
							end
						end
						else if (count % 640 >= 304 && count % 640 < 312) begin //U
							if (count/640 >= 160 && count/640 < 176) begin
								if (font_data[7 - ((count % 640) - 304)] == 1)
									color = 4'hD;
								else
									color = 4'h3;
							end
						end
						else if (count % 640 >= 312 && count % 640 < 320) begin // 
							if (count/640 >= 160 && count/640 < 176) begin
								if (font_data[7 - ((count % 640) - 312)] == 1)
									color = 4'hD;
								else
									color = 4'h3;
							end
						end
						else if (count % 640 >= 320 && count % 640 < 328) begin //W
							if (count/640 >= 160 && count/640 < 176) begin
								if (font_data[7 - ((count % 640) - 320)] == 1)
									color = 4'hD;
								else
									color = 4'h3;
							end
						end
						else if (count % 640 >= 328 && count % 640 < 336) begin //I
							if (count/640 >= 160 && count/640 < 176) begin
								if (font_data[7 - ((count % 640) - 328)] == 1)
									color = 4'hD;
								else
									color = 4'h3;
							end
						end
						else if (count % 640 >= 336 && count % 640 < 344) begin //N
							if (count/640 >= 160 && count/640 < 176) begin
								if (font_data[7 - ((count % 640) - 336)] == 1)
									color = 4'hD;
								else
									color = 4'h3;
							end
						end
						else if (count % 640 >= 344 && count % 640 < 352) begin //!
							if (count/640 >= 160 && count/640 < 176) begin
								if (font_data[7 - ((count % 640) - 344)] == 1)
									color = 4'hD;
								else
									color = 4'h3;
							end
						end
					end

					

					// draw coins
					// 3
					if (screen_pos + count % 640 >= 1000 && screen_pos + count % 640 < 1018) begin
						if (count/640 >= 224 && count/640 < 248) begin
							if (coin_color == 4'h0 || coin[1] == 1'b0)
								color = 4'h3;
							else
								color = coin_color;
						end
						else if (count/640 >= 274 && count/640 < 298) begin
							if (coin_color == 4'h0 || coin[2] == 1'b0)
								color = 4'h3;
							else
								color = coin_color;
						end
						else if (count/640 >= 324 && count/640 < 348) begin
							if (coin_color == 4'h0 || coin[3] == 1'b0)
								color = 4'h3;
							else
								color = coin_color;
						end
					end
					else if (screen_pos + count % 640 >= 1030 && screen_pos + count % 640 < 1048) begin
						if (count/640 >= 224 && count/640 < 248) begin
							if (coin_color == 4'h0 || coin[4] == 1'b0)
								color = 4'h3;
							else
								color = coin_color;
						end
						else if (count/640 >= 274 && count/640 < 298) begin
							if (coin_color == 4'h0 || coin[5] == 1'b0)
								color = 4'h3;
							else
								color = coin_color;
						end
						else if (count/640 >= 324 && count/640 < 348) begin
							if (coin_color == 4'h0 || coin[6] == 1'b0)
								color = 4'h3;
							else
								color = coin_color;
						end
					end
					else if (screen_pos + count % 640 >= 1060 && screen_pos + count % 640 < 1078) begin
						if (count/640 >= 224 && count/640 < 248) begin
							if (coin_color == 4'h0 || coin[7] == 1'b0)
								color = 4'h3;
							else
								color = coin_color;
						end
						else if (count/640 >= 249 && count/640 < 273) begin
							if (coin_color == 4'h0 || coin[8] == 1'b0)
								color = 4'h3;
							else
								color = coin_color;
						end
						else if (count/640 >= 274 && count/640 < 298) begin
							if (coin_color == 4'h0 || coin[9] == 1'b0)
								color = 4'h3;
							else
								color = coin_color;
						end
						else if (count/640 >= 299 && count/640 < 323) begin
							if (coin_color == 4'h0 || coin[10] == 1'b0)
								color = 4'h3;
							else
								color = coin_color;
						end
						else if (count/640 >= 324 && count/640 < 348) begin
							if (coin_color == 4'h0 || coin[11] == 1'b0)
								color = 4'h3;
							else
								color = coin_color;
						end
					end
					//8
					else if (screen_pos + count % 640 >= 1090 && screen_pos + count % 640 < 1108) begin
						if (count/640 >= 224 && count/640 < 248) begin
							if (coin_color == 4'h0 || coin[12] == 1'b0)
								color = 4'h3;
							else
								color = coin_color;
						end
						else if (count/640 >= 249 && count/640 < 273) begin
							if (coin_color == 4'h0 || coin[13] == 1'b0)
								color = 4'h3;
							else
								color = coin_color;
						end
						else if (count/640 >= 274 && count/640 < 298) begin
							if (coin_color == 4'h0 || coin[14] == 1'b0)
								color = 4'h3;
							else
								color = coin_color;
						end
						else if (count/640 >= 299 && count/640 < 323) begin
							if (coin_color == 4'h0 || coin[15] == 1'b0)
								color = 4'h3;
							else
								color = coin_color;
						end
						else if (count/640 >= 324 && count/640 < 348) begin
							if (coin_color == 4'h0 || coin[16] == 1'b0)
								color = 4'h3;
							else
								color = coin_color;
						end
					end
					else if (screen_pos + count % 640 >= 1120 && screen_pos + count % 640 < 1138) begin
						if (count/640 >= 224 && count/640 < 248) begin
							if (coin_color == 4'h0 || coin[17] == 1'b0)
								color = 4'h3;
							else
								color = coin_color;
						end
						else if (count/640 >= 274 && count/640 < 298) begin
							if (coin_color == 4'h0 || coin[18] == 1'b0)
								color = 4'h3;
							else
								color = coin_color;
						end
						else if (count/640 >= 324 && count/640 < 348) begin
							if (coin_color == 4'h0 || coin[19] == 1'b0)
								color = 4'h3;
							else
								color = coin_color;
						end
					end
					else if (screen_pos + count % 640 >= 1150 && screen_pos + count % 640 < 1168) begin
						if (count/640 >= 224 && count/640 < 248) begin
							if (coin_color == 4'h0 || coin[20] == 1'b0)
								color = 4'h3;
							else
								color = coin_color;
						end
						else if (count/640 >= 249 && count/640 < 273) begin
							if (coin_color == 4'h0 || coin[21] == 1'b0)
								color = 4'h3;
							else
								color = coin_color;
						end
						else if (count/640 >= 274 && count/640 < 298) begin
							if (coin_color == 4'h0 || coin[22] == 1'b0)
								color = 4'h3;
							else
								color = coin_color;
						end
						else if (count/640 >= 299 && count/640 < 323) begin
							if (coin_color == 4'h0 || coin[23] == 1'b0)
								color = 4'h3;
							else
								color = coin_color;
						end
						else if (count/640 >= 324 && count/640 < 348) begin
							if (coin_color == 4'h0 || coin[24] == 1'b0)
								color = 4'h3;
							else
								color = coin_color;
						end
					end
					//5
					else if (screen_pos + count % 640 >= 1180 && screen_pos + count % 640 < 1198) begin
						if (count/640 >= 224 && count/640 < 248) begin
							if (coin_color == 4'h0 || coin[25] == 1'b0)
								color = 4'h3;
							else
								color = coin_color;
						end
						else if (count/640 >= 249 && count/640 < 273) begin
							if (coin_color == 4'h0 || coin[26] == 1'b0)
								color = 4'h3;
							else
								color = coin_color;
						end
						else if (count/640 >= 274 && count/640 < 298) begin
							if (coin_color == 4'h0 || coin[27] == 1'b0)
								color = 4'h3;
							else
								color = coin_color;
						end
						else if (count/640 >= 324 && count/640 < 348) begin
							if (coin_color == 4'h0 || coin[28] == 1'b0)
								color = 4'h3;
							else
								color = coin_color;
						end
					end
					else if (screen_pos + count % 640 >= 1210 && screen_pos + count % 640 < 1228) begin
						if (count/640 >= 224 && count/640 < 248) begin
							if (coin_color == 4'h0 || coin[29] == 1'b0)
								color = 4'h3;
							else
								color = coin_color;
						end
						else if (count/640 >= 274 && count/640 < 298) begin
							if (coin_color == 4'h0 || coin[30] == 1'b0)
								color = 4'h3;
							else
								color = coin_color;
						end
						else if (count/640 >= 324 && count/640 < 348) begin
							if (coin_color == 4'h0 || coin[31] == 1'b0)
								color = 4'h3;
							else
								color = coin_color;
						end
					end
					else if (screen_pos + count % 640 >= 1240 && screen_pos + count % 640 < 1258) begin
						if (count/640 >= 224 && count/640 < 248) begin
							if (coin_color == 4'h0 || coin[32] == 1'b0)
								color = 4'h3;
							else
								color = coin_color;
						end
						else if (count/640 >= 274 && count/640 < 298) begin
							if (coin_color == 4'h0 || coin[33] == 1'b0)
								color = 4'h3;
							else
								color = coin_color;
						end
						else if (count/640 >= 299 && count/640 < 323) begin
							if (coin_color == 4'h0 || coin[34] == 1'b0)
								color = 4'h3;
							else
								color = coin_color;
						end
						else if (count/640 >= 324 && count/640 < 348) begin
							if (coin_color == 4'h0 || coin[35] == 1'b0)
								color = 4'h3;
							else
								color = coin_color;
						end
					end

					// draw prof
					if (screen_pos + count % 640 >= 1100 && screen_pos + count % 640 < 1220) begin
						if (count/640 >= 80 && count/640 < 180 && coin == 36'b0) begin
							if (prof_color == 4'h0)
								color = 4'h2;
							else
								color = prof_color;
						end
					end
					
				end
				
				
				else begin
					color = ground_color;
				end
			end
			
			drawMario: begin
				if (big) begin
					// big mario all 32*64
					unique case (dir)
						LEFT:
							write_addr = (character_pos_y+(count>>5))*640+character_pos_x + 31-count[4:0];
						RIGHT:
							write_addr = (character_pos_y+(count>>5))*640+character_pos_x + count[4:0];
					endcase
					if (jump)
						color = mario_big_jump_color;
					else if (walk1)
						color = mario_big_walk1_color;
					else if (walk2)
						color = mario_big_walk2_color;
					else if (walk3)
						color = mario_big_walk3_color;
					else
						color = mario_big_idle_color;
				end
				else begin
					// small mario: jump,walk1 32*32; lose 28*28; other 24*32
					if (jump) begin
						color = mario_small_jump_color;
						unique case (dir)
							LEFT:
								write_addr = (character_pos_y+(count>>5))*640+character_pos_x + 31-count[4:0];
							RIGHT:
								write_addr = (character_pos_y+(count>>5))*640+character_pos_x + count[4:0];
						endcase
					end
					else if (walk1) begin
						color = mario_small_walk1_color;
						unique case (dir)
							LEFT:
								write_addr = (character_pos_y+(count>>5))*640+character_pos_x + 31-count[4:0];
							RIGHT:
								write_addr = (character_pos_y+(count>>5))*640+character_pos_x + count[4:0];
						endcase
					end
					else if (walk2) begin
						color = mario_small_walk2_color;
						temp = count % 24;
						unique case (dir)
							LEFT:
								write_addr = (character_pos_y+(count/24))*640+character_pos_x + 23-temp;
							RIGHT:
								write_addr = (character_pos_y+(count/24))*640+character_pos_x + temp;
						endcase
					end
					else if (walk3) begin
						color = mario_small_walk3_color;
						temp = count % 24;
						unique case (dir)
							LEFT:
								write_addr = (character_pos_y+(count/24))*640+character_pos_x + 23-temp;
							RIGHT:
								write_addr = (character_pos_y+(count/24))*640+character_pos_x + temp;
						endcase
					end
					else if (lose) begin
						color = mario_small_lose_color;
						temp = count % 28;
						unique case (dir)
							LEFT:
								write_addr = (character_pos_y+(count/28))*640+character_pos_x + 27-temp;
							RIGHT:
								write_addr = (character_pos_y+(count/28))*640+character_pos_x + temp;
						endcase
					end
					else begin
						color = mario_small_idle_color;
						temp = count % 24;
						unique case (dir)
							LEFT:
								write_addr = (character_pos_y+(count/24))*640+character_pos_x + 23-temp;
							RIGHT:
								write_addr = (character_pos_y+(count/24))*640+character_pos_x + temp;
						endcase
					end		
				end
				
			end
			
			
		endcase
	
	end
	
	// in-game order: background -> trees -> cloud -> tube -> 
	//						bullet -> block -> mario
	// need a FSM for in-game sprite drawing
	
	// may need another FSM:
	// start page --press any button--> in game --win--> game over page
	//													    --restart--> Go back to start menu
	
	// drawing logic:
	// start drawing background at drawY = 240
	// (writing and VGA reading finish at the same time)
	// draw sprites during vertical blank (max pixels: 71,428)
	// Doesn't need a vs input since sprite drawing always happens
	// after background drawing, which is approximately at the start
	// of vertical sync pulse

	assign addr = write_addr;
	always_comb begin
		if (color == 4'b0000)
			we = 1'b0;
		else
			we = write_ena;
	end
endmodule
