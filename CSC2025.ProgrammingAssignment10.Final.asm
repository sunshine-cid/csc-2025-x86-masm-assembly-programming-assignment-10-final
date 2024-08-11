; Student
; Professor
; Class: CSC 2025 XXX
; Week 10 - Programming Homework #10
; Date
; Interactive Program which takes in a 25 element integer array and sorts it in various ways

INCLUDE C:\Irvine\Irvine32.inc
INCLUDELIB C:\Irvine\Irvine32.lib

.data
    ; Set several different message strings we'll be using in the program
    msgBasicInstructions BYTE "Please enter a minimum of 25 non-negative integers. The maximum entries is 300 and the maximum string length is 1MB. If you make a mistake or you input less than 25 you will be propted to try again: ", 0
    msgMistake BYTE "Please be sure you're entering 25 non-negative integers. ", 0
    msgMinimum BYTE "The minimum value entered is: ", 0
    msgMaximum BYTE "The maximum value entered is: ", 0
    msgAverage BYTE "The average of the values you entered is: ", 0
    msgOdds BYTE "The odd values you entered in the array were: ", 0
    msgEvens BYTE "The even values you entered in the array were: ", 0
    msgAgain BYTE "Would you like to repeat the program (Y/N)?", 0

    ; There are limits to our input, they are set here
    inputMax=1048576
    arrayInput BYTE inputMax+1 DUP(?)

    arrayMin DWORD 25 ; Our minimum acceptable array size
    array DWORD 300 DUP(?) ; Where we store our actual array
    arrayMinValue DWORD ? ; Where we store the smallest value input
    arrayMaxValue DWORD ? ; Where we store the biggest value input
    arrayAverageValue DWORD ? ; Where we store the average value input
    odds DWORD 300 DUP(?) ; The array where we store our odd values
    evens DWORD 300 DUP(?) ; The array where we store our even values
    arrayCount DWORD 0 ; Counter specifically for the Array_Input procedure, totals our array items
    oddsCount DWORD 0 ; A counter that tracks how many odd values we recieved
    evensCount DWORD 0 ; A counter that store how many even values we recieved

    inputAgain BYTE ? ; When asked if the program is to be repeated we store the response character here

    ; We need these character value constants to make comparisons with
    charY BYTE "Y",0
    charN BYTE "N",0

.code

;-------------------------------- Array_Input Procedure 
;	Functional Details: Practically this converts a space-delimited list of 
;   integers into an array and also counts the items
;   Inputs: Takes a string of space-delimited integers
;   Outputs: Displays an instructional message, also displays the input 
;   string, and displays a message if there is a problem with the input string
;	Registers:  EAX is used to store our integer value while reading each
;               EBX is used to hold our minimum array size
;               ECX holds our maximum input length, also used to hold the next
;               digit when calculating 10's positions when adding to EAX
;               EDX is used to hold message offsets
;               ESI is set to the offset of our storage array
;               EDI holds the offset to our input array
;               EBP is used to hold ESP and access the stack
;               ESP is transfered to EBP for accessing the stack
;	Memory Locations: arrayCount is directly accessed, and there are several 
;   message memory offsets.
Array_Input PROC

    ; I could not get pop/push to work directly since the return pointer is also pushed
    ; Looking online and in chapter 8, I learned the commonly accepted practice is to 
    ; access the stack through ESP through EBP as follows
    push ebp ; Save EPB on the stack
    mov ebp, esp ; Move our stack pointer into EPB

AIStart:

    ; Load(or Re-load) parameters from stack
    mov ecx, [ebp+8] ; Max input length
    mov edi, [ebp+12] ; Offset to out input buffer arrayInput
    mov ebx, [ebp+16] ; Our minimum array count value
    mov esi, [ebp+20] ; Offset to the beginning of our array


mov edx, OFFSET msgBasicInstructions ; Our basic instructions offset is loaded into EDX
call WriteString ; The message is displayed
call Crlf ; Carriage return for formatting purposes

mov edx, edi ; Now we're done with EDX for messages, move our input buffer offset into edx
call ReadString ; Read input. ECX was set earlier to our max length via the stack

mov arrayCount, 0 ; At the beginning our array counter should be 0

AIReadLoop: ; Our entry/repeat point for reading our string for integers
   
    AISkipSpaces:
        cmp byte ptr [edi], ' ' ; Compare our value to a space character
        jne AIDigitCheck ; If not euqal, send to check if it's a digit
        inc edi ; Otherwise, it's a space, skip by incrementing EDI
        jmp AISkipSpaces ; Jump up and test next index value
    AIDigitCheck:
        cmp byte ptr [edi], 0 ; Compare our value to 0 or NULL, 
        je AIEnd ; If true, end of string, go to end

        ; Parse the integer
        mov eax, 0  ; Clear eax to store the result

        AIParseIntegerLoop:
            cmp byte ptr [edi], '0' ; Compare value to '0'
            jb AIParseIntegerEnd  ; If below, not a digit
            cmp byte ptr [edi], '9' ; Compare value to '9'
            ja AIParseIntegerEnd  ; If above, not a digit

            ; Convert ASCII to integer and add to EAX
            sub byte ptr [edi], '0' ; Subtract base ASCII value of '0' to get literal value
            movzx ecx, byte ptr [edi] ; Move converted digit to ecx
            imul eax, eax, 10 ; Move up (by multiplying by 10) past digits placing them in proper position
            add eax, ecx ; Add the next digit
            add byte ptr [edi], '0' ; Restore digit to ASCII value so we don't corrupt our string
            inc edi ; Move on to next digit position
            jmp AIParseIntegerLoop ; Back to AIParseIntegerLoop to check for more digits or other characters

    AIParseIntegerEnd:
        cmp eax, 0 ; If the parse integer section returns a 00000000h there may have been an error. Otherwise goto AIParseIntegerSpecialEnd where we will continue with the next integer
        jne AIParseIntegerSpecialEnd

        ; If we reach here, it means there may have been an error
        cmp byte ptr [edi - 1], '0' ; check to see if our input character was '0' if it was we're good
        jne AIMistake ; otherwise AIMistake!

    AIParseIntegerSpecialEnd:

        mov [esi], eax  ; Store the parsed integer in array
        add esi, 4 ; Move on to next array index position
        inc arrayCount        ; Increment the counter

        ; Skip to the next space
        AINextSpace:
            cmp byte ptr [edi], 0  ; Compare our value to 0 or NULL, 
            je AIEnd  ; If true, end of string, go to end
            cmp byte ptr [edi], ' ' ; Compare our value to a space character
            je AIReadLoop ; If equal begin the read loop again
            inc edi ; Otherwise increment our index
            jmp AINextSpace ; And check the next space

loop AIReadLoop ; We repeat until we've repeated the length of our counter

AIEnd:
    ; Check if the correct number of integers were parsed
    cmp arrayCount, ebx ; Compare our count to our minimum (EBX)
    jl AIMistake ; If too short there's been a mistake!
    pop ebp ; restore ebp before return
ret

AIMistake:
    mov edx, OFFSET msgMistake ; load the 'there's been a mistake' message offset into edx
    call WriteString ; Write that string to the display
    call Crlf ; Carriage return for formatting purposes
    call Crlf ; Carriage return for formatting purposes
    jmp AIStart ; If we're here we need to restart the process

Array_Input ENDP

;-------------------------------- Array_Min Procedure 
;	Functional Details: This procedure finds the minimum value in our array
;   Inputs: Takes no strict input, but does access memory offsets
;   Outputs: Makes no strict output, but does return our minimum value via EAX
;	Registers:  EAX is used to hold the next value for comparison, also used to return minimum at the end
;               EBX is used to hold our determined minimum number
;               ECX is used to hol our array length
;               ESI is set to the offset of our storage array
;               EBP is used to hold ESP and access the stack
;               ESP is transfered to EBP for accessing the stack             
;	Memory Locations: No explicit memory operands are used, but we do access 
;   our array through ESI
Array_Min PROC
    
    ; I could not get pop/push to work directly since the return pointer is also pushed
    ; Looking online and in chapter 8, I learned the commonly accepted practice is to 
    ; access the stack through ESP through EBP as follows
    push ebp ; Save EPB on the stack
    mov ebp, esp ; Move our stack pointer into EPB

    ; Load parameters from stack
    mov ecx, [ebp+8] ; Length of array
    mov esi, [ebp+12] ; Offset to our array

    ; Initialize the minimum with the first element of the array
    mov eax, [esi] ; Save the first value, 
    mov ebx, eax ; w/o comparison assume it is the lowest (we've seen so far)

    ; Loop through the array
    dec ecx ; Count down our arrayCount
    add esi, 4 ; Increment ESI

AMFindMinLoop:
    mov eax, [esi] ; Grab our next value
    cmp eax, ebx ; Compare to our current lowest (EBX)
    jge AMSkipUpdateMin ; Greater or equal skip updating
    mov ebx, eax ; Otherwise update EBX to new lowest

AMSkipUpdateMin:
    add esi, 4 ; Either way we increment ESI
    loop AMFindMinLoop ; And loop decrimenting ECX

AMEndMin:
    mov eax, ebx ; Move our determined minimum value into eax for return
    pop ebp ; restore ebp before return
ret
Array_Min ENDP

;-------------------------------- Array_Max Procedure 
;	Functional Details: This procedure finds the maximum value in our array
;   Inputs: Takes no strict input, but does access memory offsets
;   Outputs: Makes no strict output, but does return our minimum value via EAX
;	Registers:  EAX is used to hold the next value for comparison, also used to return maximum at the end
;               EBX is used to hold our determined maximum number
;               ECX is used to hold our array length
;               ESI is set to the offset of our storage array
;               EBP is used to hold ESP and access the stack
;               ESP is transfered to EBP for accessing the stack             
;	Memory Locations: No explicit memory operands are used, but we do access 
;   our array through ESI
Array_Max PROC
    ; I could not get pop/push to work directly since the return pointer is also pushed
    ; Looking online and in chapter 8, I learned the commonly accepted practice is to 
    ; access the stack through ESP through EBP as follows
    push ebp ; Save EPB on the stack
    mov ebp, esp ; Move our stack pointer into EPB

    ; Load parameters from stack
    mov ecx, [ebp+8] ; Length of array
    mov esi, [ebp+12] ; Offset to our array

    ; Initialize the minimum with the first element of the array
    mov eax, [esi] ; Save the first value, 
    mov ebx, eax ; w/o comparison assume it is the highest (we've seen so far)

    ; Loop through the array
    dec ecx ; Count down our arrayCount
    add esi, 4 ; Increment ESI

AMxFindMaxLoop:
    mov eax, [esi] ; Grab our next value
    cmp eax, ebx ; Compare to our current highest (EBX)
    jle AMxSkipUpdateMax ; Lesser or equal skip updating
    mov ebx, eax ; Otherwise update EBX to new highest

AMxSkipUpdateMax:
    add esi, 4 ; Either way we increment ESI
    loop AMxFindMaxLoop ; And loop decrimenting ECX

AMxEndMax:
    mov eax, ebx ; Move our determined maximum value into eax for return
    pop ebp ; restore ebp before return
ret
Array_Max ENDP

;-------------------------------- Array_Avg Procedure 
;	Functional Details: Totals up each value in the array, divides that by the 
;   total items in the array, returns that value (as an integer)
;   Inputs: Takes no explicit input from the user, but does take the array and 
;   the length of the array from the stack
;   Outputs: Makes no explicit output but does return the average via eax
;	Registers:	EAX is used to hold our running total
;               EBX is used to hold our divisor (which it gets from ecx)
;               ECX is used to hold our array length, for counting purposes
;               EDX is cleared before our DIVision operation
;               ESI is set to the offset of our storage array
;               EBP is used to hold ESP and access the stack
;               ESP is transfered to EBP for accessing the stack 
;	Memory Locations: No explicit memory operands are used, but we do access 
;   our array through ESI
Array_Avg PROC
    ; I could not get pop/push to work directly since the return pointer is also pushed
    ; Looking online and in chapter 8, I learned the commonly accepted practice is to 
    ; access the stack through ESP through EBP as follows
    push ebp ; Save EPB on the stack
    mov ebp, esp ; Move our stack pointer into EPB

    ; Load parameters from stack
    mov ecx, [ebp+8] ; Length of array
    mov esi, [ebp+12] ; Offset to our array

    ; Getting ready, we
    mov ebx, ecx ; Load our divisor based on ecx a little early
    mov eax, 0 ; Zero our our total

AALoop:
    
    add eax, [esi] ; Add the next [esi] value to our total
    add esi, 4 ; increment our index so we can get the next value

    loop AALoop ; Repeat until ECX=0 and we've totalled all items 

AAEnd: ; Now that we're done we can divide by our array length to get our average
    mov edx, 0 ; EDX must be cleared to avoid dividing errors
    div ebx ; Divide EAX by EBX, EAX is automatically set to our average

    pop ebp ; restore ebp before return
ret
Array_Avg ENDP

;-------------------------------- Display_Array Procedure 
;	Functional Details: Is a helper procedure which displays items in an array
;   Inputs: Takes no explicit input but does recieve the length of the array 
;   and the offset of the array off the stack
;   Outputs: Explicitly outputs to the display the items in the array seperated 
;   by spaces
;	Registers:	EAX (AL) is used when displaying a space character as output
;               ECX is used to hold our array length, for counting purposes
;               ESI is set to the offset of our storage array
;               EBP is used to hold ESP and access the stack
;               ESP is transfered to EBP for accessing the stack 
;	Memory Locations: 
Display_Array PROC

    ; I could not get pop/push to work directly since the return pointer is also pushed
    ; Looking online and in chapter 8, I learned the commonly accepted practice is to 
    ; access the stack through ESP through EBP as follows
    push ebp ; Save EPB on the stack
    mov ebp, esp ; Move our stack pointer into EPB

    ; Load parameters from stack
    mov ecx, [ebp+8] ; Length of array
    mov esi, [ebp+12] ; Offset to our array

    ; Loop through the array and display each element
    DALoop:	
	mov eax, [esi] ; Move the value from [esi] into EAX
	call WriteDec ;  and write it to the screen
	
    add esi, 4 ; Increment our array index position

    mov al, ' ' ; Move the value of a space character into the AL register
    call WriteChar ; Display that character

    loop DALoop ; Repeat until we've cycled through the list based on ECX
    
    pop ebp ; restore ebp before return
	ret
Display_Array ENDP

;-------------------------------- Array_Odds Procedure 
;	Functional Details: Takes the array and searches for the odd values and 
;   creates a new array called odds which it fills in ascending order
;   Inputs: Takes no explicit input but does access our array via an offset
;   Outputs: Makes no explicit output but does create a new array via na offset
;	Registers:	EAX holds the current value for odd testing, and later in the 
;               bubble sort holds the value for the swapping that happens in 
;               that sort
;               EBX is used in the bubble sort for the inner loop counter
;               ECX is used to hold our array length, for counting purposes, 
;               then later in the bubble sort is used to hold our outer loop 
;               counter
;               EDX is used to hold a backup of our odds array index pointer
;               EDI holds our first odds array index pointer
;               ESI is set to the offset of our storage array
;               EBP is used to hold ESP and access the stack
;               ESP is transfered to EBP for accessing the stack 
;	Memory Locations: We use the oddsCount memory operand directly
Array_Odds PROC

    ; I could not get pop/push to work directly since the return pointer is also pushed
    ; Looking online and in chapter 8, I learned the commonly accepted practice is to 
    ; access the stack through ESP through EBP as follows
    push ebp ; Save EPB on the stack
    mov ebp, esp ; Move our stack pointer into EPB

    ; Load parameters from stack
    mov ecx, [ebp+8] ; Length of array
    mov esi, [ebp+12] ; Offset to our original array
    mov edi, [ebp+16] ; Offset to odds array
    mov edx, edi ; Save our odds array pointer

AOLoop:
    mov eax, [esi] ; Load the current element
    test eax, 1 ; Test if LSB is 1 (odd number)
    jz AONotOdd ; If zero, it is not odd, skip storing

    mov [edi], eax ; Store the odd number in the odds array
    add edi, 4 ; Move to the next position in the odds array
    inc oddsCount ; Increment the odd count

AONotOdd:
    add esi, 4 ; Move to the next element in the input array
    loop AOLoop ; Decrement ecx and loop if not zero

    ; Now, sort the odds array using bubble sort
    mov ecx, oddsCount ; Set ecx to the saved value of oddsCount
    mov edi, edx ; Restore our odds array pointer

    ; Bubble sort outer loop
AOSortOuterLoop:
    cmp ecx, 1 ; If there's only one or zero elements left, array is sorted
    jle AOSortEnd ; Jump to end if sorted

    mov edi, OFFSET odds ; Point to the start of the odds array
    mov ebx, ecx ; Inner loop counter
    sub ebx, 1 ; We must sub 1 from our inner counter or we'll go out of bounds

AOSortInnerLoop:
    mov eax, [edi] ; Load the current element
    mov edx, [edi+4] ; Load the next element
    cmp eax, edx ; Compare the two elements
    jle AOSortSkipSwap ; If already in order, skip swap

    ; Swap the elements
    mov [edi], edx
    mov [edi+4], eax

AOSortSkipSwap:
    add edi, 4 ; Move to the next pair of elements
    dec ebx ; Decrement the inner loop counter
    jnz AOSortInnerLoop ; Continue inner loop if not zero

    dec ecx ; Decrement the outer loop counter
    jmp AOSortOuterLoop ; Repeat the outer loop

AOSortEnd:

    pop ebp ; restore ebp before return
ret
Array_Odds ENDP

;-------------------------------- Array_Evens Procedure 
;	Functional Details: Takes the array and searches for the even values and 
;   creates a new array called evens which it fills in ascending order
;   Inputs: Takes no explicit input but does access our array via an offset
;   Outputs: Makes no explicit output but does create a new array via an offset
;	Registers:	EAX holds the current value for odd testing, and later in the 
;               bubble sort holds the value for the swapping that happens in 
;               that sort
;               EBX is used in the bubble sort for the inner loop counter
;               ECX is used to hold our array length, for counting purposes, 
;               then later in the bubble sort is used to hold our outer loop 
;               counter
;               EDX is used to hold a backup of our evens array index pointer
;               EDI holds our first evens array index pointer
;               ESI is set to the offset of our storage array
;               EBP is used to hold ESP and access the stack
;               ESP is transfered to EBP for accessing the stack 
;	Memory Locations: We use the evensCount memory operand directly
Array_Evens PROC

    ; I could not get pop/push to work directly since the return pointer is also pushed
    ; Looking online and in chapter 8, I learned the commonly accepted practice is to 
    ; access the stack through ESP through EBP as follows
    push ebp ; Save EPB on the stack
    mov ebp, esp ; Move our stack pointer into EPB

    ; Load parameters from stack
    mov ecx, [ebp+8] ; Length of array
    mov esi, [ebp+12] ; Offset to our original array
    mov edi, [ebp+16] ; Offset to evens array
    mov edx, edi ; Save our evens array pointer

AELoop:
    mov eax, [esi] ; Load the current element
    test eax, 1 ; Test if LSB is 1 (odd number)
    jnz AENotEven ; If not zero, it is not even, skip storing

    mov [edi], eax ; Store the even number in the evens array
    add edi, 4 ; Move to the next position in the evens array
    inc evensCount ; Increment the even count

AENotEven:
    add esi, 4 ; Move to the next element in the input array
    loop AELoop ; Decrement ecx and loop if not zero

    ; Now, sort the evens array using bubble sort
    mov ecx, evensCount ; Set ecx to the saved value of evensCount
    mov edi, edx ; Restore our evens array pointer

    ; Bubble sort outer loop
AESortOuterLoop:
    cmp ecx, 1 ; If there's only one or zero elements left, array is sorted
    jle AESortEnd ; Jump to end if sorted

    mov edi, OFFSET evens ; Point to the start of the evens array
    mov ebx, ecx ; Inner loop counter
    sub ebx, 1 ; We must sub 1 from our inner counter or we'll go out of bounds

AESortInnerLoop:
    mov eax, [edi] ; Load the current element
    mov edx, [edi+4] ; Load the next element
    cmp eax, edx ; Compare the two elements
    jle AESortSkipSwap ; If already in order, skip swap

    ; Swap the elements
    mov [edi], edx
    mov [edi+4], eax

AESortSkipSwap:
    add edi, 4 ; Move to the next pair of elements
    dec ebx ; Decrement the inner loop counter
    jnz AESortInnerLoop ; Continue inner loop if not zero

    dec ecx ; Decrement the outer loop counter
    jmp AESortOuterLoop ; Repeat the outer loop

AESortEnd:

    pop ebp ; restore ebp before return
ret
Array_Evens ENDP

;-------------------------------- main Procedure 
;	Functional Details: Takes in a list of integers, converts them to an array, 
;   finds min, max, and avg, finds odds (ascending sorted), finds evens 
;   (ascending sorted). Essentally this combines all the functions with an 
;   option to repeat the process if desired. We use the stak to send data to 
;   our procedures as instructed. Occasionally EAX retuns values (Min,Max, and 
;   Avg)
;   Inputs: The first precedure takes the string of integers as input. Then 
;   later we take input on if the user desires to repeat the program.
;   Outputs: Several instructional and information messages are displayed 
;   about what input is expected, and what information we're displaying
;	Registers:  EAX is used to recieve values from procedures and subsiquently
;               that information is immediately displayed via WriteDec. Later
;               we use AL to hold/display an input character related to 
;               repeating the program
;               EDX is used to hold the offsets of those informational messages
;	Memory Locations: Out array offset, and our array length are pushed to the 
;   stack almost every procedure call. Out inputArray input buffer and our 
;   inputMax are pushed to our first Array_Input procedure. odds and evens 
;   offsets are pushed to the stack for each procedure respectively. And 
;   oddsCount and evensCount are pushed to the stack when we call 
;   Display_Array. They are also 0'd when we start in the case that the 
;   program repeats.
main PROC ; main procedure entry point
    

MainStart:
    mov oddsCount, 0 ; Needs to be 0'd out in the event that this is a 2nd go around
    mov evensCount, 0 ; Needs to be 0'd out in the event that this is a 2nd go around
    
    ;*** Setup and execute our Array_Input procedure
    push OFFSET array ; Our array offset is sent to the stack
    push arrayMin ; Our arrayMin-imum value is pushed to the stack
    push OFFSET arrayInput ; Out input buffer offset is pushed to the stack
    push InputMax ; Out input max value is also puched to the stack
    call Array_Input ; We call our procedure which collects out input string and sorts it into an array of integers
    call Crlf ; Carriage return for formatting purposes

    ;*** Setup and execute our Array_Min procedure
    push OFFSET array ; Our array offset is sent to the stack
    push arrayCount ; Out total of array items is sent to the stack
    call Array_Min ; Call our procedure which determines the minimum value input in ouor array
    mov arrayMinValue, eax ; Move our Min value into arrayMinValue, always good to save!
    mov edx, OFFSET msgMinimum ; Move a message offset about the minimum value into EDX 
    call WriteString ; write that string to the display
    call WriteDec ; Write the value in EAX to the display
    call Crlf ; Carriage return for formatting purposes

    ;*** Setup and execute our Array_Max procedure
    push OFFSET array ; Our array offset is sent to the stack
    push arrayCount ; Out total of array items is sent to the stack
    call Array_Max ; Call our procedure which determines the maximum value input in our array
    mov arrayMaxValue, eax ; Move our Max value into arrayMaxValue, always good to save!
    mov edx, OFFSET msgMaximum ; Move a message offset about the maximum value into EDX 
    call WriteString ; write that string to the display
    call WriteDec ; Write the value in EAX to the display
    call Crlf ; Carriage return for formatting purposes

    ;*** Setup and execute our Array_Avg procedure
    push OFFSET array ; Our array offset is sent to the stack
    push arrayCount ; Out total of array items is sent to the stack
    call Array_Avg ; Call our procedure which determines the average value of inputs in our array
    mov arrayAverageValue, eax ; Move our Max value into arrayMaxValue, always good to save!
    mov edx, OFFSET msgAverage ; Move a message offset about the average of values into EDX 
    call WriteString ; write that string to the display
    call WriteDec ; Write the value in EAX to the display
    call Crlf ; Carriage return for formatting purposes
    call Crlf ; Carriage return for formatting purposes

    ;*** Setup and execute our Array_Odds procedure
    push OFFSET odds ; Our odds array offset is sent to the stack
    push OFFSET array ; Our array offset is sent to the stack
    push arrayCount ; Out total of array items is sent to the stack
    call Array_Odds ; This procedure takes our original array, finds the odds, and sorts those in a new array
    mov edx, OFFSET msgOdds ; Moves an offset of a message about displaying the odds into EDX
    call WriteString ; write that string to the display
    call Crlf ; Carriage return for formatting purposes
    push OFFSET odds ; Our odds array offset is sent to the stack
    push oddsCount ; oddsCount value is sent to the stack as the counter for Display_Array
    call Display_Array ; Moves through the odds array limited by oddsCounter and displays each item
    call Crlf ; Carriage return for formatting purposes
    call Crlf ; Carriage return for formatting purposes

    ;*** Setup and execute our Array_Evens procedure
    push OFFSET evens ; evens array offset is sent to the stack
    push OFFSET array ; Our array offset is sent to the stack
    push arrayCount ; Out total of array items is sent to the stack
    call Array_Evens ; This procedure takes our original array, finds the evens, and sorts those in a new array
    mov edx, OFFSET msgEvens ; Moves an offset of a message about displaying the evens into EDX
    call WriteString ; write that string to the display
    call Crlf ; Carriage return for formatting purposes
    push OFFSET evens ; evens array offset is sent to the stack
    push evensCount ; evensCount value is sent to the stack as the counter for Display_Array
    call Display_Array ; Moves through the evens array limited by evensCounter and displays each item
    call Crlf ; Carriage return for formatting purposes
    call Crlf ; Carriage return for formatting purposes
    
MainAgain: ; "Would you like to enter a new string of numbers?" portion of the program
	
	mov  edx,OFFSET msgAgain ; move the offset for our message into edx
	call WriteString ; and display it

	call ReadChar ; Take input from the user regarding repeating the program
	call WriteChar ; Display the character typed, this is necessary since ReadChar doesn't display the Char typed
	call Crlf ; Move the display line down 1
	call Crlf ; Move the display line down 1

	movsx eax, al ; we need to overwrite the rest of the EAX register with the sign from AL becasue ReadChar loads the value to AL
	mov inputAgain, al ; Store the read character in our memory operand

	INVOKE Str_ucase, ADDR inputAgain ; Convert input Char to Uppercase
	
	; Compare input character to uppercase Y, if equals jump to MainLoopStart
	mov al, inputAgain ; Move our input char value into al
	cmp al, charY ; Compare to Y
	je MainStart ; If equal, jump to the top of the program

	; Compare input to uppercase N, if equals, jump to MainExit
	cmp al, charN ; Compare our input char to N
	je MainExit ; if equal move to the exit portion of our program

	jmp MainAgain ; If neither y or n was pressed, repeat prompt

MainExit:

    exit

main ENDP

END main
