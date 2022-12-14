//Two-always example for state machine

module control (input  logic Clk, Reset, ClearALoadB, Run, M,
                output logic Clr_Ld, Shift_En, Add, Sub, Clr_A );

    // Declare signals curr_state, next_state of type enum
    // with enum values of A, B, ..., F as the state values
	 // Note that the length implies a max of 8 states, so you will need to bump this up for 8-bits
    enum logic [4:0] {A, B, C, D, E, F, G, H, I, J, K, L, S1, S2, S3, S4, S5, S6, S7, S8}   curr_state, next_state;
	 
	 assign Clr_Ld = ClearALoadB;

	//updates flip flop, current state is the only one
    always_ff @ (posedge Clk)  
    begin
        if (Reset)
            curr_state <= A;
        else 
            curr_state <= next_state;
    end

    // Assign outputs based on state
	always_comb
    begin
        
		  next_state  = curr_state;	//required because I haven't enumerated all possibilities below
        unique case (curr_state) 

				/*A :    if (Run)
							next_state = B;
            //B :    next_state = C;
				B :    next_state = S1;
				S1 :    next_state = C;
				C :    next_state = S2;
            //C :    next_state = D;
				S2 :    next_state = D;
            D :    next_state = E;
            E :    next_state = F;
            F :    next_state = G;
				G :    next_state = H;
				H :    next_state = I;
				I :    next_state = J;
				J :    next_state = K;*/
				A :    if (Run)
							next_state = B;
				B :    next_state = S1;
				S1 :    next_state = C;
				C :    next_state = S2;
				S2 :    next_state = D;
				D :    next_state = S3;
				S3 :    next_state = E;
				E :    next_state = S4;
				S4 :    next_state = F;
				F :    next_state = S5;
				S5 :    next_state = G;
				G :    next_state = S6;
				S6 :    next_state = H;
				H :    next_state = S7;
				S7 :    next_state = I;
				I :    next_state = S8;
				S8 :    next_state = K;
				K :	 if (~Run)
							next_state = L;
				J:		 next_state = B;
				L:		 if (Run)
							next_state = J;
				
				
							  
        endcase
   
		  // Assign outputs based on ‘state’
        case (curr_state)
				A:
				begin
					 Clr_A = 1'b1;
					 Shift_En = 1'b0;
					 Add = 1'b0;
					 Sub = 1'b0;
				end
				
				
	   	   B: 
		      begin
					 Clr_A = 1'b0;
					 Shift_En = 1'b0;
					 if (M == 1'b1)
						Add = 1'b1;
					 else
						Add = 1'b0;
					 Sub = 1'b0;
		      end
				
				C:
				begin
					Clr_A = 1'b0;
					Shift_En = 1'b0;
					if (M == 1'b1)
						Add = 1'b1;
					else
						Add = 1'b0;
					Sub = 1'b0;
				end
				D:
				begin
					Clr_A = 1'b0;
					Shift_En = 1'b0;
					if (M == 1'b1)
						Add = 1'b1;
					else
						Add = 1'b0;
					Sub = 1'b0;
				end
				E:
				begin
					Clr_A = 1'b0;
					Shift_En = 1'b0;
					if (M == 1'b1)
						Add = 1'b1;
					else
						Add = 1'b0;
					Sub = 1'b0;
				end
				F:
				begin
					Clr_A = 1'b0;
					Shift_En = 1'b0;
					if (M == 1'b1)
						Add = 1'b1;
					else
						Add = 1'b0;
					Sub = 1'b0;
				end
				G:
				begin
					Clr_A = 1'b0;
					Shift_En = 1'b0;
					if (M == 1'b1)
						Add = 1'b1;
					else
						Add = 1'b0;
					Sub = 1'b0;
				end
				H:
				begin
					Clr_A = 1'b0;
					Shift_En = 1'b0;
					if (M == 1'b1)
						Add = 1'b1;
					else
						Add = 1'b0;
					Sub = 1'b0;
				end
				I:
				begin
					Clr_A = 1'b0;
					Shift_En = 1'b0;
					Add = 1'b0;
					if (M == 1'b1)
						Sub = 1'b1;
					else
						Sub = 1'b0;
				end
				/*J:
				begin
					Shift_En = 1'b1;
					Sub = 1'b0;
					Add = 1'b0;
				end*/
				S1:
				begin
					 Clr_A = 1'b0;
					 Shift_En = 1'b1;
					 Add = 1'b0;
					 Sub = 1'b0;
				end
				S2:
				begin
					Clr_A = 1'b0;
					Shift_En = 1'b1;
					 Add = 1'b0;
					 Sub = 1'b0;
				end
				S3:
				begin
					Clr_A = 1'b0;
					 Shift_En = 1'b1;
					 Add = 1'b0;
					 Sub = 1'b0;
				end
				S4:
				begin
					Clr_A = 1'b0;
					 Shift_En = 1'b1;
					 Add = 1'b0;
					 Sub = 1'b0;
				end
				S5:
				begin
					Clr_A = 1'b0;
					 Shift_En = 1'b1;
					 Add = 1'b0;
					 Sub = 1'b0;
				end
				S6:
				begin
					Clr_A = 1'b0;
					 Shift_En = 1'b1;
					 Add = 1'b0;
					 Sub = 1'b0;
				end
				S7:
				begin
					Clr_A = 1'b0;
					 Shift_En = 1'b1;
					 Add = 1'b0;
					 Sub = 1'b0;
				end
				S8:
				begin
					Clr_A = 1'b0;
					 Shift_En = 1'b1;
					 Add = 1'b0;
					 Sub = 1'b0;
				end
				K:
				begin
					Clr_A = 1'b0;
					Shift_En = 1'b0;
					Sub = 1'b0;
					Add = 1'b0;
				end
				J:
				begin
					Clr_A = 1'b1;
					Shift_En = 1'b0;
					Sub = 1'b0;
					Add = 1'b0;
				end
				L:
				begin
					Clr_A = 1'b0;
					Shift_En = 1'b0;
					Sub = 1'b0;
					Add = 1'b0;
				end
        endcase
    end

endmodule
