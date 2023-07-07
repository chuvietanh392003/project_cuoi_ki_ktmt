.eqv SEVENSEG_LEFT    0xFFFF0011 	# Địa chỉ của đèn LED 7 đoạn bên trái
.eqv SEVENSEG_RIGHT   0xFFFF0010 	# Địa chỉ của đèn LED 7 đoạn bên phải 
.eqv IN_ADRESS_HEXA_KEYBOARD       0xFFFF0012  
.eqv OUT_ADRESS_HEXA_KEYBOARD      0xFFFF0014	
.eqv KEY_CODE   0xFFFF0004         	# Mã ASCII từ bàn phím, 1 byte 
.eqv KEY_READY  0xFFFF0000        	# =1 nếu có mã keycode mới
				        # Tự động xóa sau khi lw  
.eqv DISPLAY_CODE   0xFFFF000C   	# Mã ASCII để hiển thị, 1 byte 
.eqv DISPLAY_READY  0xFFFF0008   	# =1 nếu đã sẵn sàng để hiển thị  
	                               	# Tự động xóa sau khi sw  
.eqv MASK_CAUSE_KEYBOARD   0x0000034  	# Keyboard_cause    
  
.data 
bytehex     : .byte 63,6,91,79,102,109,125,7,127,111 
storestring : .space 1000			# Không gian để lưu các ký tự nhập từ bàn phím.
stringsource : .asciiz "xin chao cac ban"  # String mẫu
Message: .asciiz "\n Number of characters entered in 2s:  " 
numkeyright: .asciiz  "\n The correct number of characters is: "  
notification: .asciiz "\n Return "

.text
	li   $k0,  KEY_CODE              
	li   $k1,  KEY_READY                    
	li   $s0, DISPLAY_CODE              
	li   $s1, DISPLAY_READY  	
MAIN:
	li $s4, 0           # Dùng để đếm tổng số ký tự nhập vào
	li $s3, 0           # Dùng để đếm số vòng lặp
	li $t4, 10
	li $t5, 400         # Lưu giá trị số vòng lặp (2 giây = 400 vòng)
	li $t6, 0           # Biến đếm số ký tự nhập được trong 2s
	li $t9, 0

LOOP:
WAIT_FOR_KEY:
	lw $t1, 0($k1)              # $t1 = [$k1] = KEY_READY
	beq $t1, $zero, Polling     # Nếu $t1 == 0 thì nhảy tới Polling

MAKE_INTERUPT:
	addi $t6, $t6, 1            # Tăng biến đếm ký tự nhập được trong 2s lên 1
	teqi $t1, 1                 # Nếu $t0 = 1 thì gây ra một ngắt

Polling:
	addi $s3, $s3, 1            # Tăng số vòng lặp.
	div $s3, $t5                # Lấy số vòng lặp chia cho 400 để xác định đã được 2 giây hay chưa.
	mfhi $t7                    # Lưu phần dư của phép chia vào $t7.
	bne $t7, 0, SLEEP           # Nếu chưa được 2 giây thì nhảy đến nhãn SLEEP.

	# Nếu đã được 2 giây thì nhảy đến nhãn SETCOUNT để thực hiện in ra màn hình.
SETCOUNT:
	li $s3, 0                   # Thiết lập lại giá trị của $s3 về 0 để đếm lại số vòng lặp cho các lần tiếp theo.
	li $v0, 4                   # Bắt đầu chuỗi lệnh in ra console số ký tự nhập được trong 2 giây.
	la $a0, Message
	syscall

	# In ra số ký tự trong 2 giây.
	li $v0, 1
	add $a0, $t6, $zero
	syscall

DISPLAY_DIGITAL: 
	div $t6, $t4			# Lấy số ký tự nhập được trong 2s chia cho 10.
	mflo $t7				# Lưu giá trị phần nguyên, giá trị này sẽ được lưu vào đèn LED bên trái.
	la $s2, bytehex			# Lấy địa chỉ của danh sách lưu giá trị của từng chữ số đến LED.
	add $s2, $s2, $t7		# Xác định địa chỉ của giá trị.
	lb $a0, 0($s2)			# Lấy nội dung cho vào $a0.
	jal SHOW_7SEG_LEFT		# Ngay đến nhãn đèn LED trái.

	mfhi $t7				# Lưu giá trị phần dư của phép chia, giá trị này sẽ được in ra trong đèn LED bên phải.
	la $s2, bytehex			
	add $s2, $s2, $t7
	lb $a0, 0($s2)			# Set giá trị cho các segment.
	jal SHOW_7SEG_RIGHT		# Hiển thị.
                                          
	li $t6, 0			# Sau khi đã hoàn thành, đưa biến đếm số ký tự nhập được trong 2s về 0 để bắt đầu cho chu kỳ mới.
	beq $t9, 1, ASK_LOOP

SLEEP:  
	addi $v0, $zero, 32                   
	li $a0, 5              	# Sleep 5ms         
	syscall         
	nop    
	b LOOP          	 	# Lặp lại
END_MAIN: 
	li $v0, 10
	syscall

SHOW_7SEG_LEFT:  
	li $t0, SEVENSEG_LEFT 	# Gán địa chỉ port                   
	sb $a0, 0($t0)        	# Gán giá trị mới                    
	jr $ra 
	
SHOW_7SEG_RIGHT: 
	li $t0, SEVENSEG_RIGHT 	# Gán địa chỉ port                  
	sb $a0, 0($t0)         	# Gán giá trị mới                   
	jr $ra 

.ktext 0x80000180         	# Chương trình con chạy sau khi interrupt được gọi.         
	mfc0 $t1, $13            # Cho biết nguyên nhân làm tham chiếu địa chỉ bộ nhớ không hợp lệ.
	li $t2, MASK_CAUSE_KEYBOARD              
	and $at, $t1, $t2              
	beq $at, $t2, COUNTER_KETYBOARD              
	j END_PROCESS  
	
COUNTER_KETYBOARD: 
READ_KEY:  
	lb $t0, 0($k0)          # $t0 = [$k0] = KEY_CODE 
WAIT_FOR_DIS: 
	lw $t2, 0($s1)          # $t2 = [$s1] = DISPLAY_READY            
	beq $t2, $zero, WAIT_FOR_DIS	# Nếu $t2 == 0 thì tiếp tục Polling                             
SHOW_KEY: 
	sb $t0, 0($s0)          # Hiển thị ký tự vừa nhập từ bàn phím trên màn hình MMIO
	la $t7, storestring		# Lấy $t7 làm địa chỉ cơ sở của chuỗi nhập vào
	add $t7, $t7, $s4		
	sb $t0, 0($t7)
	addi $s4, $s4, 1
	beq $t0, 10, END                          
END_PROCESS:                         
NEXT_PC:   
	mfc0 $at, $14	        # $at <= Coproc0.$14 = Coproc0.epc              
	addi $at, $at, 4	    # $at = $at + 4 (next instruction)              
	mtc0 $at, $14	       	# Coproc0.$14 = Coproc0.epc <= $at  
RETURN:   
	eret                    # Trở về lên kế tiếp của chương trình chính
END:
	li $v0, 11         
	li $a0, '\n'         	# In xuống dòng
	syscall 
	li $t1, 0 				# Đếm số ký tự đã xét
	li $t3, 0               # Đếm số ký tự nhập đúng
	li $t8, 24				# Lưu $t8 là độ dài xâu đã lưu trữ trong mã nguồn.
	slt $t7, $s4, $t8		# So sánh xem độ dài xâu nhập từ bàn phím và độ dài của xâu cố định trong mã nguồn.
							# Xâu nào nhỏ hơn thì duyệt theo độ dài của xâu đó
	bne $t7, 1, CHECK_STRING	
	add $t8, $0, $s4
	addi $t8, $t8, -1		# Trừ 1 vì ký tự cuối cùng là dấu Enter nên không cần xét.
CHECK_STRING:			
	la $t2, storestring
	add $t2, $t2, $t1
	li $v0, 11				# In ra các ký tự đã nhập từ bàn phím.
	lb $t5, 0($t2)			# Lấy ký tự thứ $t1 trong storestring lưu vào $t5 để so sánh với ký tự thứ $t1 ở stringsource
	move $a0, $t5
	syscall 
	la $t4, stringsource
	add $t4, $t4, $t1
	lb $t6, 0($t4)			# Lấy ký tự thứ $t1 trong stringsource lưu vào $t6
	bne $t6, $t5, CONTINUE	# Nếu 2 ký tự thứ $t1 giống nhau thì tăng biến đếm số ký tự đúng lên 1
	addi $t3, $t3, 1
CONTINUE: 
	addi $t1, $t1, 1		# Sau khi so sánh 1 ký tự, tăng biến đếm lên 
	beq $t1, $t8, PRINT		# Nếu đã duyệt hết số ký tự cần xét thì in ra màn hình số ký tự nhập đúng
	j CHECK_STRING			# Còn không thì tiếp tục xét tiếp các ký tự 
PRINT:	
	li $v0, 4
	la $a0, numkeyright
	syscall
	li $v0, 1
	add $a0, $0, $t3
	syscall
	li $t9, 1
	li $t6, 0				# Sau khi kết thúc chương trình, số ký tự đúng được lưu vào $t6 rồi quay trở về phần hiển thị.
	li $t4, 10				# Thanh ghi $t4 gán trở lại giá trị 10 ở lệnh trên $t4 lưu giá trị địa chỉ của source code
	add $t6, $0, $t3
	b DISPLAY_DIGITAL 
ASK_LOOP: 
	li $v0, 50
	la $a0, notification
	syscall
	beq $a0, 0, MAIN		
	b EXIT
EXIT:
