TITLE CSC 323: Program 4 - Network Simulator      (G1P4.asm)
INCLUDE Irvine32.inc


.data


menuString BYTE "-----------------------------------------------------------------------------------------------", 10, 13				; string for menu display
		   BYTE "Please enter the number representing your intended menu option below", 10, 13
		   BYTE " ", 10, 13
		   BYTE "1. Describe network topology from the keyboard", 10, 13
		   BYTE " ", 10, 13
		   BYTE "2. Describe network topology from a file", 10, 13
		   BYTE " ", 10, 13
		   BYTE "3. Use default network topology", 10, 13
		   BYTE " ", 10, 13
		   BYTE "4. Quit", 10, 13
		   BYTE "-----------------------------------------------------------------------------------------------", 10, 13, 0

menuChoice	BYTE "Enter a choice: ", 0
badChoice	BYTE "Error, invalid menu option. Please enter the number representing the valid menu option.", 0

netString  BYTE "-----------------------------------------------------------------------------------------------", 10, 13
		   BYTE "The topology must be in the format 'A:BE B:ACF C:BDE D:CF E:ACF F:BDE'", 10, 13
		   BYTE " ", 10, 13
		   BYTE "where 'A' is the node and 'BE' are the nodes that A connects to", 10, 13
		   BYTE " ", 10, 13
		   BYTE "and the nodes that A connects to must also connect back to A.", 10, 13
		   BYTE " ", 10, 13
		   BYTE "You also must enter the nodes and connected node in alphabetical order.", 10, 13
		   BYTE " ", 10, 13
		   BYTE "For example: 'A:BE B:ACF C:BDE'", 10, 13
		   BYTE " ", 10, 13
		   BYTE "the source nodes are in order 'A, B, C' and the nodes A connects to are 'BE' also in order.", 10, 13
		   BYTE "-----------------------------------------------------------------------------------------------", 10, 13, 0
netChoice  BYTE "Enter your network topology: ", 0
		   BYTE "Enter ! to return to the previous menu", 0
		   BYTE "Enter * to quit", 0
MaxNodeSt  BYTE "The maximum number of nodes that can be entered: ", 0
MaxConnSt  BYTE "The maximum number of connections per node: ", 0



bufferSize EQU 41													; constant value to represent buffer size
byteCount  DWORD ?													; string to hold input buffer bytecount
buffer	   BYTE bufferSize DUP(0)										; array to act as input buffer
wordbuffer BYTE bufferSize DUP(0)									; array to act as word buffer
charCount SDWORD ?
counter SDWORD ?
tempCounter SDWORD ?
nodeCounter SDWORD ?
connectCounter SDWORD ?
linkCounter SDWORD ?
checkCounter SDWORD ?
tempNum SDWORD ?
bufferCounter SDWORD 0

DECIMAL_POINT			EQU		46
SIZE_DECIMAL_STRING		EQU		20

realToString			REAL8	23230.010
tenThousand				SDWORD	10000			; for multiplication on FPU stack
ten						SDWORD	10				; for division
zero					BYTE	0
realIntegerPortion		SDWORD	0				; stores the integer part of a real
realFractionPortion		SDWORD	0				; stores the fractin part of a real
junkValueToPop			REAL8	0.0


completeFractionAsString	BYTE SIZE_DECIMAL_STRING DUP(0)
							BYTE 0
positionInString			DWORD 0					; tracks position within string so completed string can be generated

tempRealNumber			BYTE	20 DUP(0), 0	; stores the growing string, x allows tracking of unused space
realAsString			BYTE	20 DUP(0), 0	; stores the result of the real-->string oepration
realAsStringCharCount	BYTE	0				; stores the char count of the real number as string

null EQU 0															; constant value to represent null character
tab EQU 9															; constant value to represent tab character 

invNum DWORD ?														; variable for signifying if a number is valid
number SDWORD ?														; variable to hold number

NodePointer				DWORD 0						; current node pointer
ProcessPointer			DWORD 0						; current node being processed pointer
NodeName				BYTE ' ', 0					; node name
NodeFrom				BYTE ' ', 0					; node from name
MessagePointer			DWORD initPacket			; current message pointer
echof					BYTE false					; echo/no echo flag
procf					BYTE false
firstTime				BYTE false
firstTimeL				BYTE false
AFlag					BYTE true
system_time				WORD 0						; system time
newpackets				WORD 0						; number of new packets generated
generatedpackets		WORD 0						; number of generated packets
totalpackets			WORD 0						; number of total generated packets
activepackets			WORD 1						; number of active packets
receivedpackets			WORD 0						; number of packets received by destination
totalhops				WORD 0						; total hops of packets to reach destination
totaltime				WORD 0						; total time of packets to reach destination
DefaultTTL				BYTE 6

avgtime					REAL8 0.0					; real for average time for packets to reach their destination
avghops					REAL8 0.0					; real for average hops for a message to reach it's destination
msgpercent				REAL8 0.0					; real for percentage of messages that reached their destination
hundred					REAL8 100.0					; real for multiplication
junkValue				REAL8 0.0					; junk value for clearing floating-point stack


NULL				EQU 0			; Null Ascii
NEW_LINE			EQU 10			; newline character ASCII
CARRIAGE_RETURN		EQU 13			; carriage return character ASCII
FILE_NAME_LENGTH	EQU 81			; sets max length of file name to 81 (minus 1 null)
FILE_BUFFER_SIZE	EQU 100			; sets max file buffer to 100

; Files, Messages
promptOutputFile		BYTE "Please enter the name of your output file including the .txt extension:", NEW_LINE, CARRIAGE_RETURN, 0
promptFileInput			BYTE "Please enter the name of your input file including the .txt extension:", NEW_LINE, CARRIAGE_RETURN, 0
fileOpenError			BYTE "Error opening file. Exiting...", 0
fileWriteError			BYTE "Error writing file. Exiting...", 0 
msgNoInput				BYTE "No input found in file. Please try again...", 0

; Files, Memory Declarations
fileName				BYTE FILE_NAME_LENGTH DUP(0)			; creates a memory block for the name of the file
outputFileHandle		DWORD ?									; handler for output file
inputFileName			BYTE FILE_NAME_LENGTH DUP(0)			; creates a memory block for the name of the file
inputFileHandle			DWORD ?
newLineChar				BYTE NEW_LINE							; will be used to insert newline into file
						BYTE 0
numberToWrite			DWORD 0									; will hold a numerical value so can write to file
stringNumberToWrite		SBYTE 5 DUP(0)							; holds the forward string after reversal
						SBYTE 0									; null terminator to previous variable
tempStringNumber		SBYTE 5 DUP('x')						; used to hold number as string before removing 'x' values
						SBYTE 0	
charCountString			DWORD 0


; Node Offsets
NameOffset				EQU 0						; name offset
NumConnOffset			EQU 1						; number of connections offset
QueueAddress			EQU 2						; address for the start of the queue
InPointer				EQU 6						; transmit queue InPointer offset
OutPointer				EQU 10						; transmit queue OutPointer offset

ConnectionSize			EQU 12
BaseSizeOfStructure		EQU 14

; Node Connection Offsets
Connection				EQU 0						; offset to pointer to the connected node
XMT						EQU 4						; offset to transmit buffer pointer
RCV						EQU 8						; offset to receive buffer pointer


; Packet Offsets
Destination				EQU 0						; target offset
Sender					EQU 1						; last sender offset
Origin					EQU 2						; source offset
TTL						EQU 3						; ttl offset
Received				EQU 4						; receive time offset

PacketSize				EQU 6						; packet size

initPacket				BYTE PacketSize DUP(0)		; initial packet

tempPacket				BYTE PacketSize DUP(0)		; temp packet buffer

MaxNodes				EQU 12
MaxConnNode				EQU 10
NodeCount				BYTE 0
TotalConnections		BYTE 0
XMTBuffer				BYTE PacketSize * MaxNodes DUP(0)
RCVBuffer				BYTE PacketSize * MaxNodes DUP(0)
NodesBuffer				BYTE MaxNodes * ((MaxConnNode * ConnectionSize) + BaseSizeOfStructure) DUP(0)


QueueSize				EQU 200
NodeQueues				BYTE MaxNodes * QueueSize * PacketSize DUP(0)
QueueStep				EQU QueueSize * PacketSize

DefaultTopology			BYTE "A:BE B:ACF C:BDE D:CF E:ACF F:BDE", 0

; Strings
sourcenode				BYTE "Source Node:  ", 0
destinationnode			BYTE "Destination Node:  ", 0
ttlvalue				BYTE "TTL: ", 0
echomess				BYTE "Echo", 0
noechomess				BYTE "No Echo", 0
timeis					BYTE "Time is ", 0
ProcessingOut			BYTE "       Processing outgoing queue of  ", 0
ProcessingRcv			BYTE "       Processing the receive buffers of  ", 0
MsgRcv					BYTE "              A message was received from  ", 0
DestinationRcv			BYTE "                        The message reached it's destination from  ", 0
MsgDied					BYTE "                     The message died.", 0
AtTime					BYTE "                   At time ", 0
MessageReceived			BYTE " the message was received from  ", 0
MessageGenerated		BYTE "                      A message is generated for  ", 0
MessageSent				BYTE "                                 The message was sent.", 0
MessageNotSent			BYTE "                                 The message was not sent.", 0
ThereAre				BYTE "                   There are ", 0
ThereAre2				BYTE "       There are ", 0
NewMessages				BYTE " new messages.", 0
MessagesActiveAnd		BYTE " messages active, ", 0
MessagesHaveBeen		BYTE " messages have been generated in this time, ", 0
TotalMessagesHaveBeen	BYTE "and a total of ", 0
MessagesExisted			BYTE " messages existed in the network.", 0
fullQueueString			BYTE "Transmit queue is full, aborting...", 0
alphaString				BYTE "Error: Non-alpha character entered", 0
nonalphaTable			BYTE "~`!*@#$%^&()_-+={}[]|\;<,>.?/", 0				; string containg non-alpha characters
QuitString				BYTE "Quitting program...", 0
SimSymbol				BYTE "***********************************************************************************************", 0
NetInfo					BYTE "Network Simulation Information: ", 0
TotalInfo				BYTE "Total time for network simulation: ", 0
TotalMsg				BYTE "Total messages generated in the network simulation: ", 0
TotalPack				BYTE "Total packets that reached their destination: ", 0
AvgDestTime				BYTE "Average time for the packets to reach their destination: ", 0
AvgHopDest				BYTE "Average hops for a message to reach it's destination: ", 0
PercentMsg				BYTE "Percentage of messages that reached their destination: ", 0
blankLine				BYTE " ", 0

tempBuffer BYTE bufferSize DUP(0)
tempBuffer2 BYTE bufferSize DUP(0)
tempChar BYTE ' ', 0
BadTop BYTE "Bad network topology read. Returning to main menu...", 0
GoodTop BYTE "Good network topology read. Proceeding...", 0
echoPrompt BYTE "Enter Y for echo mode and N for no echo mode: ", 0
badEchoPrompt BYTE "Bad input for echo option. Please choose a correct option.", 0
sourcePrompt BYTE "Enter source node: ", 0
destPrompt BYTE "Enter destination node: ", 0
badSourcePrompt BYTE "Bad input for source node. Please choose a correct option.", 0
badDestPrompt BYTE "Bad input for destination node. Please choose a correct option.", 0
samePrompt BYTE "It is pointless to send a message to yourself. Please choose another destination node.", 0
badBufferString BYTE "Bad input read. Returning to main menu....", 0


.code

main PROC
	mov system_time, 0						; system time
	mov totalpackets, 1						; init number of total generated packets
	mov activepackets, 1					; number of active packets
	mov receivedpackets, 0					; number of packets received by destination
	mov totalhops, 0						; total hops of packets to reach deestination
	mov totaltime, 0						; total time of packets to reach destination
	finit

	TheMenu:
		mov edx, OFFSET menuString			; print menu to screen
		call WriteString
		call Crlf
		call Crlf
		mov edx, OFFSET menuChoice			; prompt for choice
		call WriteString
		call getInput
		call SkipSpace
		call getNumber						; get the choice
		jc BadEntry							; if it's bad jump to BadEntry
		jmp GoodEntry						; otherwise jump to GoodEntry

	BadEntry:
		call Crlf
		mov edx, OFFSET badChoice			; print error message
		call WriteString
		call Crlf
		call Crlf
		jmp TheMenu							; jump back to main menu

	GoodEntry:
		; 1. Keyboard
		; 2. File
		; 3. Default
		; 4. Quit
		cmp number, 1
		je TheKeyboard						; if option 1 is chosen, jump to TheKeyboard
		cmp number, 2
		je TheFile							; if option 2 is chosen, jump to TheFile
		cmp number, 4
		je TheQuit							; if option 3 is chosen, jump to TheQuit
		jmp TheDefault						; otherwise we jump to TheDefault as its the only other possible outcome

		TheKeyboard:
			mov edx, OFFSET netString		; print string
			call WriteString
			call Crlf
			mov edx, OFFSET MaxNodeSt		; print maximum number of nodes string
			call WriteString
			mov eax, MaxNodes				; print maximum number of nodes allowed
			call WriteDec
			call Crlf
			mov edx, OFFSET MaxConnSt		; print maximum number of node connections string
			call WriteString
			mov eax, MaxConnNode			; print maximum number of node connections allowed
			call WriteDec
			call Crlf
			call Crlf
			mov edx, OFFSET netChoice		; prompt for network from keyboard
			call WriteString
			call getInput
			jmp EndMenu

		TheFile:
			mov edx, OFFSET netString		; print string
			call WriteString
			call Crlf
			mov edx, OFFSET MaxNodeSt		; print maximum number of nodes string
			call WriteString
			mov eax, MaxNodes				; print maximum number of nodes allowed
			call WriteDec
			call Crlf
			mov edx, OFFSET MaxConnSt		; print maximum number of node connections string
			call WriteString
			mov eax, MaxConnNode			; print maximum number of node connections allowed
			call WriteDec
			call Crlf
			call Crlf
			CALL getInputFileName
			JC TheMenu						; indicates error in file
			CALL getTopologyFromFile
			JC TheMenu
			mov byteCount, SIZEOF buffer
			mov ebx, 0
			jmp EndMenu

		TheQuit:
			call Crlf
			mov edx, OFFSET QuitString		; print that were quitting the program
			call WriteString
			call Crlf
			jmp EndMain						; quit

		TheDefault:							; copy default topology to buffer
			cld			
			mov esi, OFFSET DefaultTopology
			mov ecx, LENGTHOF DefaultTopology
			mov edi, OFFSET buffer
			rep movsb
			mov byteCount, SIZEOF buffer
			mov ebx, 0						; set buffer index to 0
		EndMenu:
			

	call ConfirmNumNodes					; confirm number of nodes in the network
	call CheckBuffer						; check that the buffer is in the right format
	jc TheMenu								; if it's not, jump back to the main menu
	call ConfirmTopology					; confirm that the network topology is good
	jc TheMenu								; if it's not, jump back to the main menu	
	call Crlf
	mov edx, OFFSET GoodTop					; print that the topology is good
	call WriteString
	call Crlf
	call Crlf
	call LoadNodeNameConn					; load the name and number of connections for each node into the node structures
	call LinkNodes							; link the nodes and their respective XMT and RCV buffers
	
	TheEcho:
		mov edx, OFFSET echoPrompt			; prompt for echo mode
		call WriteString
		call getInput						; get the input
		call SkipSpace
		call getWord
		call convertToUpper					; convert it to uppercase
		mov ecx, 0							; clear ecx
		cmp wordbuffer[ecx], 'Y'			; check if 'Y' entered
		je YesFound							; then jump to YesFound
		cmp wordbuffer[ecx], 'N'			; check if 'N' entered
		je NoFound							; then jump to NoFound
		
		mov edx, OFFSET badEchoPrompt		; otherwise print an error msg
		call WriteString
		call Crlf
		jmp TheEcho							; jump back to TheEcho and reprompt for a correct option

	YesFound:
		mov echof, true						; set to echo mode
		jmp TheSource

	NoFound:
		mov echof, false					; set to no echo mode

	TheSource:
		call Crlf
		mov edx, OFFSET sourcePrompt		; prompt for source node
		call WriteString
		call getInput						; get the input
		call SkipSpace
		call getWord
		call convertToUpper					; convert to uppercase
		call Crlf
		mov edi, OFFSET NodesBuffer
		CheckSource:
			mov ecx, 0
			mov edx, 0
			mov eax, 0
			mov esi, 0
			mov al, NameOffset[edi]			; move nodename to al
			cmp al, null					; check if the name is not null
			je SourceIsBad					; if it is, jump to SourceIsBad
			cmp wordbuffer[ecx], al			; check if the source node entered is the node we are currently pointing to
			je SourceIsGood					; if it is, jump to SourceIsGood
			mov dl, NumConnOffset[edi]		; traverse to next node
			add edi, BaseSizeOfStructure
			mov eax, ConnectionSize
			mul edx
			add edi, eax
			jmp CheckSource					; jump back up to CheckSource
		SourceIsBad:
			mov edx, OFFSET badSourcePrompt	; print error msg
			call WriteString
			call Crlf
			jmp TheSource					; jump back up to TheSource and reprompt for good input
		SourceIsGood:
			; move source to packet
			mov edi, OFFSET initPacket
			mov byte ptr Sender[edi], al
			mov byte ptr Origin[edi], al
			mov word ptr Received[edi], 0
			mov NodeFrom, al						; move to NodeFrom for comparison to Destination node



	TheDestination:
		mov edx, OFFSET destPrompt					; prompt for destination node
		call WriteString
		call getInput								; get the input
		call SkipSpace
		call getWord
		call convertToUpper							; convert to uppercasse
		call Crlf
		mov edi, OFFSET NodesBuffer
		CheckDest:
			mov eax, 0
			mov ecx, 0
			mov edx, 0
			mov esi, 0
			mov cl, NodeFrom						; get the source node into cl
			mov al, NameOffset[edi]					; get current nodename into al
			cmp al, null							; check if the current node name is null
			je DestIsBad							; if it is it is bad, so jump to DestIsBad
			cmp wordbuffer[esi], cl					; otherwise compare current node name to node source name
			je SameNode								; if they are the same, jump to SameNode
			cmp wordbuffer[esi], al					; otherwise compare current node name to the name entered
			je DestIsGood							; if they are equal, then jump to DestIsGood
			mov dl, NumConnOffset[edi]				; traverse to next node
			add edi, BaseSizeOfStructure
			mov eax, ConnectionSize
			mul edx
			add edi, eax
			jmp CheckDest
		DestIsBad:
			mov edx, OFFSET badDestPrompt			; display error msg
			call WriteString
			call Crlf
			jmp TheDestination						; jump back up to TheDestination and reprompt for good input
		SameNode:
			mov edx, OFFSET samePrompt				; display error msg
			call WriteString
			call Crlf
			jmp TheDestination						; jump back up to TheDestination and reprompt for good input
		DestIsGood:
			; move destination to packet
			mov edi, OFFSET initPacket
			mov byte ptr Destination[edi], al
			mov al, DefaultTTL
			mov byte ptr TTL[edi], al

	ThePacket:
		mov edi, OFFSET initPacket
		mov al, Destination[edi]
		mov NodeName, al
		mov al, Sender[edi]
		mov NodeFrom, al

		; initialize Node Pointer to start of structure
		mov NodePointer, OFFSET NodesBuffer			; put Node A, beginning of structure, address in Node Pointer
		mov edi, NodePointer						; get current Node Pointer
		mov bl, NodeFrom							; get Source Node
		mov nodeCounter, 0

		Call GetFileName						; get user fileName

	findSource:									; locate source Node
		cmp byte ptr NameOffset[edi], bl		; check if this is the Source Node
		je finishFind							; found the Source Node
		mov ecx, 0								; clear ecx
		mov cl, NumConnOffset[edi]				; get number of connections
		add edi, BaseSizeOfStructure			; move to connection space of structure
		mov eax, ConnectionSize					; get size of each connection
		mul ecx									; determine size of all bl connections
		add edi, eax							; offset edi over all connections to next node
		mov NodePointer, edi					; update NodePointer with new node
		inc nodeCounter
		mov ebx, 0
		mov bl, NodeCount
		cmp byte ptr nodeCounter, bl
		jl findSource							; check next node
		mov NodePointer, OFFSET NodesBuffer			; requested Node not found, use Node A

	finishFind:
		mov MessagePointer, OFFSET initPacket	; put init packet address in Message Address
		call PutIt								; copy init Message into Node A transmit queue
		jc fullqueueabort						; full transmit queue, abort program

		









	mainloop:					; start of main program loop
	; eax used for addition, subtraction, byte manipulation
	; ebx used for connection counter
	; ecx used for size of string to write
	; edx used for string writing
	; edi used for pointer to connected node
	; esi used for node structure pointer
		;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;; Transmit Loop ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
	; process transmit
	
	mov nodeCounter, 0
	MOV ecx, 1									; sets length
	MOV edx, OFFSET newLineChar
	clc
	call PrintMessage
	mov edx, OFFSET timeis						; print time is message
	mov ecx, SIZEOF timeis						; get size of message
	mov eax, 0
	mov ax, system_time							; get number to print
	stc											; include crlf
	call PrintMessageNumber						; print the message and the number
	mov NodePointer, OFFSET NodesBuffer				; init node pointer to node a structure
	mov generatedpackets, 0						; init generated packets for this time

	xmtloop:									; start of xmt loop
		inc nodeCounter
		mov esi, NodePointer					; get Node structure address
		mov ProcessPointer, esi					; keep copy of what node is being currently processed
		mov edx, OFFSET ProcessingOut			; get Processing ... message address
		mov eax, SIZEOF ProcessingOut			; get size of Processing message
		add edx, eax							; add together
		sub edx, 2								; adjust to node name position

		; move node name into message
		mov al, NameOffset[esi]					; get node name
		mov [edx], al							; put node name into message
		mov NodeName, al						; keep Node Name
		mov edx, OFFSET ProcessingOut			; get Processing ... message address
		mov ecx, SIZEOF ProcessingOut			; get size of output buffer
		stc										; include crlf
		call PrintMessage


		mov procf, false
		; get the packet from the transmit queue
		mov MessagePointer, OFFSET tempPacket		; get temporary packet location
		call GetIt									; check if there is a message to transmit
		jc MoveToNextXmt						; no message in queue, move to the next node
		mov procf, true
	
		; Only if there is a message to send, process the connections
		; get number of connections to process for the node
		mov ebx, 0									; clear ebx
		mov bl, NumConnOffset[esi]					; get number of connections
		mov edi, OFFSET tempPacket					; get temp packet address, this has the packet

		; print At time ...
		mov edx, OFFSET AtTime						; get At time ... message address
		mov ecx, SIZEOF AtTime						; get size of message
		mov eax, 0									; clear eax
		mov ax, Received[edi]						; Get time from packet
		clc											; do not include crlf
		call PrintMessageNumber						; print message


		mov edx, OFFSET MessageReceived				; get Message received from ...
		mov eax, SIZEOF MessageReceived				; get size of Message received from
		add edx, eax								; add together
		sub edx, 2									; adjust to node name position

		; get node from message in xmt queue packet, temppacket
		mov al, Sender[edi]							; get sending node
		mov [edx], al								; put node name into message
		mov NodeFrom, al							; keep sending node name
		mov al, NodeName
		mov Sender[edi], al							; update Node Name in Message
		mov edx, OFFSET MessageReceived				; get Message Received from ... message address
		mov ecx, SIZEOF MessageReceived				; get size of output buffer
		stc											; include crlf
		call PrintMessage							; print message

		; initialize packet counters
		mov newpackets, -1							; reset new packet counter
		dec generatedpackets						; adjust generated packets so received
													; packet, one from transmit queue, is not double counted
		dec totalpackets							; adjust total generated packets so
													; received, one from transmit queue, is not double counted
		dec activepackets							; adjust active packets so packet, one from transmit queue,
													; is not double counted

		; process each connection
		add esi, BaseSizeOfStructure				; move to connection space of structure
		
		XmtNodeLoop:
			mov edx, OFFSET MessageGenerated		; get Message Generated for ... message
			mov eax, SIZEOF MessageGenerated		; get size of Message Generated for message
			add edx, eax							; add together
			sub edx, 2								; adjust to node name position

			; get connection node name
			mov edi, Connection[esi]				; get address of connected node structure
			mov al, NameOffset[edi]					; get node name
			mov [edx], al							; put node name into message
			mov edx, OFFSET MessageGenerated		; get Message Generated for ... message
			mov ecx, SIZEOF MessageGenerated		; get size of output buffer
			stc										; include crlf
			call PrintMessage						; print message
			cmp echof, true							; test if echo
			je SendIt
			cmp NodeFrom, al						; check if connection is the sender
			je DontSend

			SendIt:
				inc activepackets						; count the active packets
				inc newpackets							; count the new message
				inc generatedpackets					; count the generated packets					; do we count generated packets even if we don't send them?
				inc totalpackets						; count the total generated packets

				; copy tempPacket to transmit buffer for this connection
				call SendPacket							; send the message
				mov edx, OFFSET MessageSent				; get output buffer
				mov ecx, SIZEOF MessageSent				; get size of output buffer
				stc										; include crlf
				call PrintMessage						; print message
				jmp MoveToNextXmt

			DontSend:
				mov edx, OFFSET MessageNotSent			; get output buffer
				mov ecx, SIZEOF MessageNotSent			; get size of output buffer
				stc										; include crlf
				call PrintMessage						; print message

			MoveToNextXmt:
				; move to next connection in current structure
				add esi, ConnectionSize					; move to next connection
				dec ebx									; count the processed node connection
				cmp ebx, 0
				jg XmtNodeLoop							; process next connection of current node
				cmp procf, true
				jne NextNode
			
				PrintNewMsg:							; print the number of new messages generated at this time
					push eax
					push ecx
					push edx
					mov ax, newpackets
					mov edx, OFFSET ThereAre
					mov ecx, SIZEOF ThereAre
					clc
					call PrintMessageNumber
					mov edx, OFFSET NewMessages
					mov ecx, SIZEOF NewMessages
					stc
					call PrintMessage
					pop edx
					pop ecx
					pop eax

				NextNode:
					mov edi, ProcessPointer					; set edi to the currently processed node
					mov eax, 0								; clear eax
					mov al, NumConnOffset[edi]				; get number of connections
					mov cl, ConnectionSize					; get size of each connection
					mul cl									; determine size of all connections
					add edi, BaseSizeOfStructure			; move to connection space of structure
					add edi, eax							; offset esi over all connections to next node
					mov NodePointer, edi
					mov ecx, 0
					mov cl, NodeCount
					cmp byte ptr nodeCounter, cl
					jl xmtloop


	; When Transmit Loop Is Complete
	mov edx, OFFSET ThereAre2						; print There are ... message
	mov ecx, SIZEOF ThereAre2						; get size of message
	mov eax, 0										; clear number to print
	mov ax, activepackets							; get active packets to print
	clc												; do not include crlf
	call PrintMessageNumber							; print the message and the number
	mov edx, OFFSET MessagesActiveAnd				; print active messages
	mov ecx, SIZEOF MessagesActiveAnd				; get size of message
	mov eax, 0										; clear the number to print
	mov ax, generatedpackets						; get number of generated packets
	clc												; do not include crlf
	call PrintMessageNumber							; print the message and the number

	mov edx, OFFSET MessagesHaveBeen				; print have been generated
	mov ecx, SIZEOF MessagesHaveBeen				; get size of message
	mov eax, 0										; clear the number to print
	mov ax, totalpackets							; print number of generated packets
	clc												; do not include crlf
	call PrintMessage							; print the message and the number
	mov edx, OFFSET TotalMessagesHaveBeen
	mov ecx, SIZEOF TotalMessagesHaveBeen
	clc
	call PrintMessageNumber
	mov edx, OFFSET MessagesExisted			; print total have been generated
	mov ecx, SIZEOF MessagesExisted			; get size of message
	stc												; include crlf
	call PrintMessage
	MOV ecx, 1								; sets length
	MOV edx, OFFSET newLineChar				; will print newline Char without any text
	clc
	call PrintMessage
	inc system_time									; update time

	mov NodePointer, OFFSET NodesBuffer
	mov edx, OFFSET timeis						; print time is message
	mov ecx, SIZEOF timeis						; get size of message
	mov eax, 0
	mov ax, system_time							; get number to print
	stc											; include crlf
	call PrintMessageNumber						; print the message and the number


		mov nodeCounter, 0
		rcvloop:
		mov esi, NodePointer
		mov ProcessPointer, esi					; keep copy of what node is being currently processed

		mov edx, OFFSET ProcessingRcv			; get Processing ... message address
		mov eax, SIZEOF ProcessingRcv			; get size of Processing message
		add edx, eax							; add together
		sub edx, 2								; adjust to node name position

		; move node name into message
		mov al, NameOffset[esi]					; get node name
		mov NodeName, al
		mov [edx], al							; put node name into message
		mov edx, OFFSET ProcessingRcv			; get Receiving ... message address
		mov ecx, SIZEOF ProcessingRcv			; get size of output buffer
		stc										; include crlf
		call PrintMessage
		mov newpackets, 0
		mov ebx, 0								; clear ebx
		mov bl, NumConnOffset[esi]
		add esi, BaseSizeOfStructure

		RcvNodeLoop:
			mov edi, RCV[esi]
			mov al, Destination[edi]
			cmp al, 0
			; if 0, no message received from this connection, proceed to next connection in this node
			je MoveToNextRcv
			; build message
			mov edx, OFFSET MsgRcv
			mov eax, SIZEOF MsgRcv
			add edx, eax
			sub edx, 2

			mov al, Sender[edi]					; build message received message
			mov [edx], al
			mov edx, OFFSET MsgRcv
			mov ecx, SIZEOF MsgRcv
			stc
			call PrintMessage					; print message
		
			mov al, Destination[edi]
			cmp al, NodeName						; check if message is intended for this node
			jne NotMine								; if its not, jump to NotMine
			inc receivedpackets						; increment receivedpackets
			dec activepackets						; decrement active packets because the message reached it's destination

			mov ecx, 0								; clear ecx
			mov al, TTL[edi]						; move current TTL to al
			mov cl, DefaultTTL						; move the DefaultTTL to cl
			sub cl, al								; subtract al from cl to get the total hops it took for the message to reach the destination
			add totalhops, cx						; add to the total hops counter
			; save average hops somewhere
			mov edx, OFFSET DestinationRcv			; print that the message reached its destination
			mov eax, SIZEOF DestinationRcv
			add edx, eax
			sub edx, 2
			mov al, Sender[edi]
			mov [edx], al
			mov edx, OFFSET DestinationRcv
			mov ecx, SIZEOF DestinationRcv
			stc
			call printMessage
			; proceed to next connection in this node
			jmp MoveToNextRcv

			NotMine:
				mov al, TTL[edi]					; mov current TTL to al
				dec al								; decrement al
				mov TTL[edi], al					; move the d
				cmp al, 0							; check if message died
				je PacketDied						; if it did, jump to PacketDied
				mov ax, system_time					; otherwise, move system time to ax
				mov Received[edi], ax				; then set the packet's received time to the system time
				mov MessagePointer, edi				; move edi to MessagePointer for use in PutIt
				call PutIt
				jc fullqueueabort					; queue is full, jump to fullqueueabort
				; proceed to next connection in this node
				jmp MoveToNextRcv
				PacketDied:
					mov edx, OFFSET MsgDied			; print that the message died
					mov ecx, SIZEOF MsgDied
					stc								; set the carry
					call PrintMessage
					dec activepackets				; decrement activepackets since the message died
				; proceed to next connection in this node

			MoveToNextRcv:
			mov al, 0
			mov Destination[edi], al
			; move to next connection in current structure
			add esi, ConnectionSize						; move to next connection
			mov al, Destination[edi]
			dec ebx										; count the processed node connection
			cmp ebx, 0
			jg RcvNodeLoop
				NextRcvNode:
					inc nodeCounter
					mov edi, ProcessPointer				; set edi to the currently processed node
					mov eax, 0							; clear eax
					mov al, NumConnOffset[edi]			; get number of connections
					mov cl, ConnectionSize				; get size of each connection
					mul cl								; determine size of all connections
					add edi, BaseSizeOfStructure		; move to connection space of structure
					add edi, eax						; offset esi over all connections to next node
					mov ecx, 0
					mov cl, NodeCount
					cmp byte ptr nodeCounter, cl
					mov NodePointer, edi				; set edi to the next node
					jl rcvloop
					mov ebx, 0							; clear ebx
					cmp activepackets, 0
					jg mainloop

	
					mov edx, OFFSET blankLine
					mov ecx, SIZEOF blankLine
					stc
					call PrintMessage

					mov edx, OFFSET SimSymbol
					mov ecx, SIZEOF SimSymbol
					STC
					CALL PrintMessage

					mov edx, OFFSET NetInfo
					mov ecx, SIZEOF NetInfo
					STC
					CALL PrintMessage

					mov edx, OFFSET blankLine
					mov ecx, SIZEOF blankLine
					stc
					call PrintMessage

					mov edx, OFFSET TotalInfo
					mov ecx, SIZEOF TotalInfo
					mov eax, 0
					mov ax, system_time
					STC
					CALL PrintMessageNumber
					

					mov edx, OFFSET TotalMsg
					mov ecx, SIZEOF TotalMsg
					mov ax, totalpackets
					STC
					CALL PrintMessageNumber

					mov edx, OFFSET TotalPack
					mov ecx, SIZEOF TotalPack
					STC
					mov ax, receivedpackets
					CALL PrintMessageNumber

					mov edx, OFFSET AvgDestTime
					mov ecx, SIZEOF AvgDestTime
					CLC
					CALL PrintMessage

					fild system_time
					fild receivedpackets
					fdiv
					fstp realToString
					CALL floatToString
					MOV edx, OFFSET completeFractionAsString
					mov ecx, SIZEOF completeFractionAsString
					STC												; adds carriage return
					CALL PrintMessage
					fld junkValue

					mov edx, OFFSET AvgHopDest
					mov ecx, SIZEOF AvgHopDest
					clc
					call PrintMessage
					

					fild totalhops
					fild receivedpackets
					fdiv
					fstp realToString
					call floatToString
					mov edx, OFFSET completeFractionAsString
					mov ecx, SIZEOF completeFractionAsString
					stc
					call PrintMessage
					fld junkValue

					mov edx, OFFSET PercentMsg
					mov ecx, SIZEOF PercentMsg
					CLC
					CALL PrintMessage

					fild receivedpackets							
					fidiv generatedpackets																
					fstp realToString								
					CALL FloatToString
					MOV Edx, OFFSET completeFractionAsString
					MOV ecx, SIZEOF completeFractionAsString
					stc
					CALL PrintMessage

					mov edx, OFFSET blankLine
					mov ecx, SIZEOF blankLine
					stc
					call PrintMessage

					mov edx, OFFSET SimSymbol
					mov ecx, SIZEOF SimSymbol
					stc
					call PrintMessage

					mov edx, OFFSET blankLine
					mov ecx, SIZEOF blankLine
					stc
					call PrintMessage

					jmp EndMain
fullqueueabort:
	call Crlf
	mov edx, OFFSET fullQueueString				; print full queue message
	call WriteString
	call Crlf
EndMain:
	exit
main ENDP

CheckBuffer PROC
	pushad						; save the registers

	; make sure number of nodes is not greater than max
	; make sure number of connections for any single node is not greater than max connections per node
	; for a, b, c, d, e, f -- make sure neither one occurs again in front of the :
	; for a, b, c, d, e, f -- make sure it doesn't occur in its own space after the : 
	; for a, b, c, d, e, f -- make sure that the same letter doesn't appear more than once in the same word such as a:bb
	; make sure no digits in the buffer

	mov al, NodeCount				; move node count to al
	cmp al, MaxNodes				; check if it's greater than the max number of allowed node
	jg BadBuffer					; if it is, jump to BadBuffer
	mov edx, 0						; clear edx

	mainLoop:
		call SkipSpace
		call getWord				; get first node's info from the buffer
		jc BadBuffer				; if no input, jump to BadBuffer
		inc edx						; increment edx
		mov ecx, charCount			; mov charCount to ecx
		sub ecx, 2					; decrement by 2 to make sure we only include the connection info
		cmp ecx, MaxConnNode		; compare number of connections to the maximum number of allowed connections per node
		jg BadBuffer				; if it's greater, jump to BadBuffer
		cmp dl, NodeCount			; check if we went through all the nodes
		je ContinueBuffer			; if we did, jump to ContinueBuffer
		jmp mainLoop				; otherwise loop

		ContinueBuffer:
			mov ebx, 0				; reset to beginning of buffer

			ContinueBuffer2:
				mov checkCounter, 0		; set checkCounter to 0
 				mov eax, 0				; clear eax
				mov ecx, 0				; clear ecx
				mov edi, 0				; clear edi
				call SkipSpace
				call getWord			; get first node's info
				jc GoodBuffer			; if end of buffer, jump to GoodBuffer
				mov al, wordbuffer[0]	; move the first character to al, the node's name
				cmp wordbuffer[1], ':'	; check if the 2nd character is a colon
				jne BadBuffer			; if it isn't jump to BadBuffer
				add edi, 2
				CheckSelf:
					inc checkCounter	; increment checkCounter
					call CheckConnectionRange		; check if there are duplicate node names in the connection info
					jc BadBuffer					; if there is, jump to BadBuffer
					mov cl, wordbuffer[edi]			; move current character to cl
					cmp cl, al						; check if it is the same character as al
					je BadBuffer					; if it is, jump to BadBuffer -- a node cannot connect to itself
					mov eax, charCount
					sub eax, 2
					inc edi
					cmp checkCounter, eax			; check if we have processed all connections of this node
					jne CheckSelf					; if we haven't jump back up to CheckSelf to process next connection
					jmp ContinueBuffer2				; otherwise jump to ContinueBuffer2 to process the next node's info

	BadBuffer:
		call Crlf
		mov edx, OFFSET badBufferString		; print error message
		call WriteString
		call Crlf
		call Crlf
		stc									; set the carry
		jmp EndLoop							; jump to EndLoop
	GoodBuffer:
		clc
	EndLoop:
	popad									; restore the registers
	ret										; return
CheckBuffer ENDP

CheckConnectionRange PROC
	pushad						; save the registers
	push counter				; save counter
	push tempCounter			; save tempCounter
	mov counter, 0				; set counter to 0
	mov tempCounter, 0			; set tempCounter to 0
	; edi is pointing to the current character
	; so check just each character of the buffere here and then return
		
	mov esi, 0					; clear esi
	mov eax, 0					; clear eax
	mov ecx, charCount			; move charCount to ecx
	sub ecx, 2					; decrement by 2 to only include connection info

	ProcessChar:
		mov al, wordbuffer[esi]		; check if the character is a digit
		call IsDigit
		jz SetCarry
		cmp wordbuffer[edi], al		; check if they are the same character
		jne NextChar				; if they are not, jump to NextChar
		inc counter					; otherwise, increment counter

	NextChar:
		cmp tempCounter, ecx		; compare ecx to tempCounter
		jg BeforeEnd				; if it's greater then we are done, so jump to BeforeEnd
		inc tempCounter				; otherwise, increment temp counter
		inc esi						; increment esi
		jmp ProcessChar				; jump to ProcessChar to check the next character in the buffer


	BeforeEnd:
		cmp counter, 1				; check if counter is greater than 1
		jg SetCarry					; if it is, jump to SetCarry since that means we are trying to connect to the same node twice
		jmp TheEnd					; otherwise jump to TheEnd
	SetCarry:
		stc							; set the carry
	TheEnd:
		pop tempCounter				; restore tempCounter
		pop counter					; restore counter
		popad						; restore the registers
		ret
CheckConnectionRange ENDP

LoadNodeNameConn PROC
	pushad							; save the registers
	mov nodeCounter, 0
	mov esi, OFFSET NodesBuffer		; set esi to the beginning of the NodesBuffer
	mov edi, OFFSET NodeQueues		; set edi to the beginning of the NodeQueues
	mainLoop:
		call SkipSpace
		call getWord				; get the current node's information
		mov al, wordbuffer[0]		; copy the node's name to the structure
		mov NodeName, al
		mov NameOffset[esi], al

		mov al, byte ptr charCount
		sub al, 2
		mov NumConnOffset[esi], al	; copy the number of connections to the structure

		mov QueueAddress[esi], edi	; set the queue address
		mov InPointer[esi], edi		; set the inpointer
		mov OutPointer[esi], edi	; set the outpointer

		inc nodeCounter


		; move esi to next node
		mov ProcessPointer, esi			; keep record of current processed node
		mov eax, 0
		mov ecx, 0
		mov al, NumConnOffset[esi]
		mov cl, ConnectionSize
		mul cl
		add esi, BaseSizeOfStructure
		add esi, eax
		add edi, QueueStep
		mov eax, dword ptr nodeCounter
		cmp eax, dword ptr NodeCount
		jne mainLoop					; if we aren't at the last node, jump back up to mainLoop
		popad							; restore the registers
		ret								; return
LoadNodeNameConn ENDP


LinkNodes PROC
	pushad								; save the registers
	mov connectCounter, 0				; set connectCounter to 0
	mov linkCounter, 0					; set linkCounter to 0
	mov ebx, 0							; clear ebx
	mov esi, OFFSET NodesBuffer			; set esi to beginning of NodesBuffer
	mov nodeCounter, 0					; set nodeCounter to 0

	mainLoop:
	; get node to process
	mov firstTime, true
	mov firstTimeL, true
	call SkipSpace
	call getWord

	mov al, wordbuffer[0]				; move node name into al

	; get number of connections for the node to process
	mov ecx, 0
	mov cl, NumConnOffset[esi]
	mov byte ptr tempNum, cl

	; move the connections to tempBuffer
	mov tempCounter, 0
	mov counter, 0
	call clearTempbuffer
	mov edi, 0
	mov ecx, 0
	add ecx, 2
	mov edx, tempNum
	MoreBuffer:
		cmp edx, tempCounter
		je NodeConnects
		mov al, wordbuffer[ecx]
		mov tempBuffer[edi], al
		inc ecx
		inc edi
		inc tempCounter
		jmp MoreBuffer


	; find node that is current character of tempbuffer
	; start from first node
	NodeConnects:
		mov edi, OFFSET NodesBuffer
		mov ecx, 0
		dec tempCounter				; decrement tempCounter for comparison with ecx since ecx starts at 0 index
		ProcessConnect:
			cmp ecx, tempCounter	; process the connection
			jg NextNode
			mov al, tempBuffer[ecx]
			cmp al, NameOffset[edi]
			jne NextConnection
			call LinkBuffers		; link the XMT and RCV buffers
			call LinkPointers		; link the connection pointers
			inc ecx
			jmp ProcessConnect		; loop
		NextConnection:				; process next connection
			mov eax, 0
			mov al, NumConnOffset[edi]
			mov dl, ConnectionSize
			mul dl
			add edi, BaseSizeOfStructure
			add edi, eax
			jmp ProcessConnect


	NextNode:					; go to process next node
	inc nodeCounter
	mov eax, 0
	mov al, byte ptr tempNum
	mov cl, ConnectionSize
	mul cl
	add esi, BaseSizeOfStructure
	add esi, eax
	mov cl, NodeCount
	cmp byte ptr nodeCounter, cl
	jl mainLoop
	popad					; restore the registers
	ret						; returns
LinkNodes ENDP

LinkPointers PROC
	pushad
	push tempNum
	mov tempNum, ecx 
	; connect each connection in the 2 current nodes

	mov ecx, edi					; make ecx point to NodeB		; does this work?
	add esi, BaseSizeOfStructure	; get to connection structure of NodeA
	add ecx, BaseSizeOfStructure	; get to connection structure of NodeB
	cmp firstTimeL, true
	jne Otherwise
	jmp LinkThem
	Otherwise:
		mov eax, 0								; clear eax
		mov dl, byte ptr tempNum			; move connection number to dl
		mov al, ConnectionSize		; move size of connection to al
		mul dl						; multiply
		add esi, eax				; go to next connection in structure
	LinkThem:
		mov Connection[esi], edi		; give NodeA pointer to NodeB
		mov firstTimeL, false
		pop tempNum
		popad
		ret
LinkPointers ENDP


LinkBuffers PROC
	pushad							; save the registers
	push ecx						; save ecx
	push eax						; save eax
	push ebx						; save ebx
	mov eax, 0						; clear eax
	mov al, NumConnOffset[edi]		; move number of connections to al
	mov ebx, 1						; set ebx to 1
	add edi, BaseSizeOfStructure	; get to connection space of node structure
	NextConn:
		mov ecx, XMT[edi]								; eax is number of connections, ebx is a counter for which connection we are on
		cmp ecx, 0										; if ecx is 0, then we are fine to move forward with the linking
		je ProceedOn								
		add edi, ConnectionSize							; proceed to next connection
		cmp eax, ebx									; if eax and ebx are equal, then we are on the last connection so proceed on
		je ProceedOn									; jump to ProceedOn
		jmp NextConn									; otherwise jump to NextConn
	ProceedOn:
		pop ebx											; restore ebx
		pop eax											; restore eax
		pop ecx											; restore ecx
			
	push tempNum										; save tempNum
	mov tempNum, ecx									; move ecx to tempNum
	mov ebx, OFFSET XMTBuffer
	mov ecx, OFFSET RCVBuffer
	add esi, BaseSizeOfStructure		; connection structure of NodeA
	cmp firstTime, true					; check if this is our first time through for this node structure
	jne Otherwise						; if we aren't, then jump to Otherwise
	jmp LinkThem						; if we are, jump to LinkThem
	Otherwise:
		mov eax, 0						; clear eax
		mov dl, byte ptr tempNum		; move connection number to dl
		mov al, ConnectionSize 
		mul dl							; multiply
		add esi, eax					; go to next connection in structure
	LinkThem:
		mov eax, XMT[esi]
		cmp eax, 0
		jne EndLoop						; if XMT is not null then the XMTRCV buffers are already linked
		IncrementBuff:
			cmp AFlag, true
			je BufferLinking
			inc bufferCounter
			push eax
			mov eax, 0
			mov edx, 0
			mov al, PacketSize
			mov dl, byte ptr bufferCounter
			mul dl
			add ebx, eax
			add ecx, eax
			pop eax
		BufferLinking:
			mov XMT[esi], ebx				; NodeA XMT
			mov RCV[esi], ecx				; NodeA RCV
			mov XMT[edi], ecx				; NodeB XMT
			mov RCV[edi], ebx				; NodeB RCV
										; NodeA XMT -> NodeB RCV || NodeB XMT -> NodeA RCV
	EndLoop:
		mov firstTime, false
		mov AFlag, false
		pop tempNum						; restore tempNum
		popad							; restore the registers
		ret								; return
LinkBuffers ENDP

ConfirmNumNodes PROC
	pushad
	mov counter, 0
	LoopDeloop:
		call SkipSpace
		jc EndLoop
		inc ebx
		jmp LoopDeloop
	EndLoop:
		inc counter					; number of nodes is 1 more than the number of spaces
		mov al, byte ptr counter
		mov NodeCount, al
		dec counter					; We need counter to now contain the number of spaces in the buffer
		popad
		ret
ConfirmNumNodes ENDP

ConfirmTopology PROC
	pushad								; save the registers

	; now we must check if the current "word" (a:be) contains "b:" and then if it contains "and a"
	; we do this for each connection in "a:be", and then if its not found, move onto the next "word", quit if its not found at all in the buffer
	; we then move to the next "word" for the compare

	mainLoop:
		mov nodeCounter, 0
		mov connectCounter, 0
		mov tempCounter, 0
		call SkipSpace
		call getWord					; get the node's information
		jc GoodTopology					; if buffer is empty, the topology is good, jump to GoodTopology
		mov esi, 0
		mov ecx, 0
		mov al, wordbuffer[ecx]			; otherwise we will move the first character to tempChar
		mov tempChar, al
		add ecx, 2						; add 2 to ecx to account for first 2 characters
	MoveToBuffer:
		mov al, wordbuffer[ecx]			; keep moving characters to tempBuffer until we have all connection name's
		mov tempBuffer[esi], al
		cmp ecx, charCount				; check if we copied all the connections
		je FindConnections				; if we did, jump to FindConnections
		inc ecx							; otherwise increment ecx
		inc esi							; increment esi
		jmp MoveToBuffer				; jump back up to MoveToBuffer to copy next connection
	FindConnections:
		push esi
		mov ecx, charCount
		mov connectCounter, ecx
		sub connectCounter, 3
		mov eax, 0
		mov edi, 0
		mov esi, 0
		FindConnections2:
			mov al, tempBuffer[esi]			; copy connect name to al
			mov tempBuffer2[edi], al		; now move it to tempBuffer2
			inc edi
			mov tempBuffer2[edi], ':'		; next move the colon to tempBuffer2
			pushad
			mov ebx, 0						; reset ebx
			mov ecx, 0						; reset ecx
		ContinueFind:
			call SkipSpace
			call getWord					; get the node's information
			cld
			mov esi, OFFSET wordbuffer
			mov edi, OFFSET tempBuffer2
			mov ecx, 2
			repe cmpsb						; check if wordbuffer and tempBuffer2 are equal
			jne NextNode					; if they aren't, go to NextNode
			mov edi, OFFSET wordbuffer		
			mov ecx, LENGTHOF wordbuffer
			mov al, tempChar
			cld
			repne scasb						; check if wordbuffer contains the node we are currently on
			jnz NextNode
			mov nodeCounter, 0
			popad
			jmp NextConnection
		NextNode:							; proceed to next node
			inc nodeCounter
			mov ecx, nodeCounter
			cmp ecx, dword ptr NodeCount
			jg NotFound
			jmp ContinueFind

	NotFound:
		pop esi
		call Crlf
		mov edx, OFFSET BadTop			; print error msg
		call WriteString
		call Crlf
		call Crlf
		stc								; set the carry
		jmp TheEnd
	NextConnection:						; move to the next connection		
		mov ecx, connectCounter
		cmp ecx, tempCounter
		je ProcessNextNode
		inc tempCounter
		inc esi
		mov edi, 0
		jmp FindConnections2
	ProcessNextNode:					; process the next node
		pop esi
		jmp mainLoop
	GoodTopology:
		clc								; clear the carry to indicate that the topology is good
	TheEnd:
		popad
		ret
ConfirmTopology ENDP


getInput PROC
	mov byteCount, 0												; initialize bytecount to 0
	mov buffer, 0													; initialize buffer to 0
	mov edx, OFFSET buffer											; read command line
	mov ecx, SIZEOF buffer - 1
	call ReadString
	mov byteCount, eax												; keep byte count
	mov ebx, 0														; initialize buffer index (ebx) to 0
	ret																; return
getInput ENDP

SkipSpace PROC
	; save registers
	push edi
	push ecx
	push edx
	push esi
	mainLoop:
		cmp ebx, byteCount											; compare ebx to end of line
		jge EmptyEnd												; jump to end if nothing to process
		mov al, buffer[ebx]											; move buffer character into al
		cmp al, null												; check if the character is null
		je EmptyEnd													; if it is, jump to end
		cmp al, ' '													; check if the character is a space
		je NextChar													; if it is, we'll grab the next character
		cmp al, tab													; check if the character is a tab
		je NextChar													; if it is, we'll grab the next character
		jmp FoundChar												; otherwise, we found the character
	NextChar:
		inc ebx														; increment index
		inc counter
		jmp mainLoop												; repeat main loop
	FoundChar:
		clc															; found a character, so clear the carry
		jmp EndLoop													; jump to end
	EmptyEnd:
		stc															; didn't find any characters, so set the carry
	EndLoop:
		; restore registers
		pop esi
		pop edx
		pop ecx
		pop edi
		ret															; return
SkipSpace ENDP

clearWordbuffer PROC
	; save registers
	push edi
	push eax
	mov al, 0														; move 0 to al
	mov edi, OFFSET wordbuffer										; move memory location of word buffer to edi
	mov ecx, LENGTHOF wordbuffer									; move length of wordbuffer to ecx
	cld																; compare forward
	rep stosb														; move null character from al to every location in wordbuffer
	; restore registers
	pop eax
	pop edi
	ret																; return
clearWordbuffer ENDP

clearTempbuffer PROC
	push edi
	push eax
	push ecx
	mov al, 0
	mov edi, OFFSET tempBuffer
	mov ecx, LENGTHOF tempBuffer
	cld
	rep stosb
	pop ecx
	pop eax
	pop edi
	ret
clearTempbuffer ENDP

getWord PROC
	; save registers
	push eax
	push edi
	push ecx
	push edx
	push esi
	call clearWordbuffer											; clear the wordbuffer
	mov edi, 0														; initialize wordbuffer index (edi) to 0
	mainLoop:
		cmp ebx, byteCount											; check if end of line
		jge EndBuffer												; if it is, jump to EndBuffer
		cmp al, null												; check if character is null
		je EndBuffer												; if it is, jump to EndBuffer
		call searchAlpha											; check if character is a non-alpha
		jc NonAlpha													; if it is, jump to NonAlpha
		cmp al, ' '													; check if character is a space
		je EndBuffer												; if it is, jump to EndBuffer
		cmp al, tab													; check if character is a tab
		je EndBuffer												; if it is, jump to EndBuffer
		mov wordbuffer[edi], al										; otherwise it is a good character and we move it into wordbuffer
		inc ebx														; increment input buffer index
		inc edi														; increment wordbuffer index
		mov al, buffer[ebx]											; move character from input buffer into al
		jmp mainLoop												; repeat
	NonAlpha:
		call Crlf
		mov edx, OFFSET alphaString									; print nonalpha character error message
		call WriteString
		call Crlf
	EndBuffer:
		cmp edi, 0													; check if wordbuffer has something
		jne HaveEnd													; if it does, jump to HaveEnd
		stc															; otherwise it doesn't, set the carry
		jmp EndLoop													; jump to end
	HaveEnd:
		mov wordbuffer[edi], null									; move null terminating character to end of wordbuffer
		clc															; clear the carry
	EndLoop:
		; restore registers
		mov charCount, edi
		pop esi
		pop edx
		pop ecx
		pop edi
		pop eax
		ret															; return
getWord ENDP

getNumber PROC
	; save registers
	push eax
	push edi
	push ecx
	push edx
	push esi
	mov edx, ebx													; move current ebx value to edx
	mov number, 0													; initialize number to 0
	mov invNum, 0													; initialize invNum to 0
	mainLoop:
		cmp ebx, byteCount											; check if end of line
		jge EndDigit												; if it is, jump to EndDigit
		mov al, buffer[ebx]											; otherwise move character from buffer to al
		cmp al, null												; check if character is null
		je EndDigit													; if it is, jump to EndDigit
		cmp al, '1'													; check if character is less than 0
		jl EndDigit													; if it is, jump to EndDigit
		cmp al, '4'													; check if character is greater than 9
		jg EndDigit													; if it is, jump to EndDigit
		and al, 0fh													; AND the character with 0fh to convert the character into a digit
		cbw															; convert the character (now a byte) into a word
		cwd															; convert the character (now a word) into a dword
		movzx ecx, al												; move and extend the digit into the ecx register
		mov eax, number												; move number (earlier intialized to 0) to eax register
		push ebx													; save ebx register
		mov ebx, 10													; move 10 to ebx (for multiplying the digit by 10)
		mul ebx														; multiply the digit by 10 (the result is stored in eax)
		add eax, ecx												; add the value of our number variable to our digit
		pop ebx														; get back original ebx value
		mov number, eax												; move the result to the number variable so it can be used on loop reentry
		inc ebx														; increment ebx so we can move to the next character
		jmp mainLoop												; loop
	EndDigit:
		cmp edx, ebx												; compare current ebx to edx (our initial ebx value)
		jne GoodNum													; if they are not equal we have something, so jump to GoodNum
		cmp ebx, byteCount											; check if end of line
		jge SetCarry												; if it is, jump to SetCarry
		Other:
			mov invNum, 1											; otherwise, it is an invalid number so mov 1 to invNum
		SetCarry:
		stc															; set the carry
		jmp EndLoop													; jump to end
	GoodNum:
		clc															; clear the carry
	EndLoop:
		; restore registers
		pop esi
		pop edx
		pop ecx
		pop edi
		pop eax
		ret															; return
getNumber ENDP

convertToUpper PROC
	; save the registers
	push eax
	push ebx
	push ecx
	push edx
	push edi
	push esi
	mov ecx, LENGTHOF wordbuffer							; move length of wordbuffer to ecx
	mov esi, OFFSET wordbuffer								; move the memory location of wordbuffer to esi
	Convert:
		and byte ptr [esi], 0dfh							; convert the character that esi is currently pointing to to uppercase, or if already is uppercase it stays uppercase
		inc esi												; increment esi
		loop Convert										; loop for the number of times equal to the length of wordbuffer
	; restore the registers
	pop esi
	pop edi
	pop edx
	pop ecx
	pop ebx
	pop eax
	ret														; return
convertToUpper ENDP

searchAlpha PROC
	; save the registers
	push eax
	push ecx
	push edx
	push esi
	push edi
	mov edi, OFFSET nonalphaTable							; move the memory location of nonalphaTable to edi
	mov ecx, LENGTHOF nonalphaTable							; move the length of nonalphaTable to ecx
	cld														; compare forward
	repne scasb												; scan nonalphaTable to see if it contains what al currently is
	jnz GoodSearch											; if it doesn't then we have no non-alpha characters, jump to GoodSearch
	BadSearch:
		stc													; we found a non-alpha character, so set the carry
		jmp EndLoop											; jump to end
	GoodSearch:
		clc													; search was good, so clear the carry
	EndLoop:
		; restore the registers
		pop edi
		pop esi
		pop edx
		pop ecx
		pop eax
		ret													; return
searchAlpha ENDP

PutIt PROC
	pushad
	mov edx, NodePointer				; set current node

	; Copy bytes of Message to Queue at the location InPointer is referencing
	cld
	mov esi, MessagePointer				; msg address in esi
	mov edi, InPointer[edx]				; in pointer in edi
	mov ecx, PacketSize					; get bytes to move
	rep movsb							; move the bytes

	; Update the InPointer to be the next memory block in the queue. Move into EAX, but DONT update the InPointer quite yet
	mov eax, InPointer[edx]				; get in pointer
	add eax, PacketSize					; update in pointer

	; Calculate the end of the queue
	mov ebx, QueueAddress[edx]			; start of queue within the current node (referenced by EDX)
	add ebx, QueueSize					; end of queue 
	
	; Now check if our InPointer (memory address in EAX) is within the bounds of our queue
	cmp eax, ebx						; in pointer past end of queue? EAX has new InPointer location. EBX has the startOf Queue
	jl put1								; not past end of queue
	
	; Make queue circular
	mov eax, QueueAddress[edx]			; get start of queue if InPointer has exceeded size of Queue

put1:
	mov InPointer[edx], eax				; update in pointer--> if InPointer exceeded, updates with startOfQueue. If not exceeded, updates to new location

	; calculate in pointer after the put
	mov eax, InPointer[edx]				; get in pointer
	add eax, PacketSize					; add packetsize (next location)

	; Compare the In and Out pointer to identify a full queue. Must normalize the address (meaning make it relative to zero) before comparison
	sub eax, QueueAddress[edx]			; subtract base address (normalize offset)
	mov ebx, OutPointer[edx]			; get out pointer
	sub ebx, QueueAddress[edx]			; subtract base address (normalize offset)
	cmp eax, ebx						; compare in to out
	je FullQueue						; queue is full, jump

QueueNotFull:		
	clc									; queue not full, clear carry
	jmp EndPutIt						; jump to end
FullQueue:
	stc									; queue full, set carry
EndPutIt:
	popad
	ret
PutIt ENDP


GetIt PROC
	; MessagePointer variable must be set to correct address
	; Status Indicators
	;		Carry Flag --> 1
	;			Empty Queue
	;		Carry Flag --> 0
	;			Success

	PUSHAD							
	mov edx, NodePointer					; places start of node into edx

	; Check if empty queue (InPointer == OutPointer)
	mov eax, InPointer[edx]					; points to end of Queue
	mov ebx, OutPointer[edx]				; adds memory address to edi
	cmp eax, ebx							; Number of bytes to move
	JE EmptyQueue
	
	;If not empty, get data--> MessagePointer
	cld								; set direction of copy
	mov esi, OutPointer[edx]		; Source of bytes to copy
	mov edi, MessagePointer			; Destination of copied bytes
	mov ecx, PacketSize				; Number of iterations to count
	rep MOVSB						; Copy bytes esi --> edi


	; Update the out pointer to the new position (value retrieved into messagePointer is technically 'used')
	mov eax, OutPointer[edx]
	add eax, PacketSize				; updates pointer

	; Calculate the end of the queue
	mov ebx, QueueAddress[edx]			; start of queue within the current node (referenced by EDX)
	add ebx, QueueSize					; end of queue 

	; check if out pointer went past end of queue
	cmp eax, ebx						; out pointer past end of queue? EAX has new OutPointer location. EBX has the startOf Queue
	jl get1							; not past end of queue

	; Circular queue
	mov eax, QueueAddress[edx]		; Get the start of the queue to reset it to zero since exceeded queue boundaries

get1:
	mov OutPointer[edx], eax				; update out pointer--> if OutPointer exceeded, updates with startOfQueue. If not exceeded, updates to new location

NotEmpty:
	CLC					; indicates success
	JMP EndGetIt

EmptyQueue:
	STC					; indicates empty queue

EndGetIt:
	POPAD
	RET
GetIt ENDP



SendPacket PROC
; take temporary packet and copy it to the
; current connection transmit buffer
; XMT is transmit buffer offset		
	pushad
	mov edx, esi
	cld
	mov esi, OFFSET tempPacket
	mov edi, XMT[edx]
	mov ecx, PacketSize
	rep movsb
	popad
	ret
SendPacket ENDP




PrintMessage PROC
	; use carry to determine if we add crlf
	; print message to screen
	; print message to file

	; transparant function
	PUSHAD
	
	JC CarriageReturn					; jumps to CarriageReturn if Carry flag set

NoCarriageReturn:
	; Write to terminal
	call WriteString

	; write sourcenode to file
	MOV eax, outputFileHandle
	;edx already loaded with proper offset
	; ecx already loaded with number of bytes to read
	CALL WriteToFile

	JMP EndPrintMessage

CarriageReturn:
	; Write to terminal
	call WriteString
	call CRLF

	; write sourcenode to file
	MOV eax, outputFileHandle
	; edx already loaded with proper offset
	; ecx already loaded with number of bytes to read
	CALL WriteToFile

	; write newline to file
	MOV eax, outputFileHandle
	MOV edx, OFFSET newLineChar					; contains ASCII 10 == newline character
	MOV ecx, 1									; want to read single byte
	call WriteToFile
	
	JMP EndPrintMessage

FileErrorTerminate:
	MOV edx, OFFSET fileWriteError
	MOV ecx, SIZEOF fileWriteError
	call WriteString
	call WaitMsg
	exit								; exits program when encountering a file error

EndPrintMessage:
	POPAD
	RET

PrintMessage ENDP


PrintMessageNumber PROC
	; use carry to determine if we add crlf
	; print message to screen
	; print message to file

	; transparant function
	PUSHAD
	MOV numberToWrite, eax				; moves number into variable so we can write to file using offset
	JC CarriageReturn					; jumps to CarriageReturn if Carry flag set

NoCarriageReturn:
	; Write to terminal
	call WriteString
	call WriteDec

	; write sourcenode to file
	MOV eax, outputFileHandle
	; edx already loaded with proper offset
	DEC ecx													; removes extra space at end of the message
	CALL WriteToFile


	call IntegerToString				

	; write number to file
	MOV eax, outputFileHandle 						; moves handle back into the eax register for another write
	MOV edx, OFFSET stringNumberToWrite					; moves number offset into edx
	MOV ecx, charCountString										; only writing one byte
	CALL WriteToFile

	JMP EndPrintMessage

CarriageReturn:
	; Write to terminal
	call WriteString
	call WriteDec
	call crlf

	; write edx offset to file
	mov eax, outputFileHandle
	; edx already loaded with proper offset
	DEC ecx											; removes extra space at end of the message
	CALL WriteToFile

	Call IntegerToString							; function to handle conversion

	; Print number to file
	mov eax, outputFileHandle
	mov edx, OFFSET stringNumberToWrite
	mov ecx, SIZEOF charCountString
	call WriteToFile
	

	; Print Carriage return
	mov eax, outputFileHandle					; output file handler
	mov edx, OFFSET newLineChar					; memory offset required for function
	mov ecx, 1									; only one char printed
	call WriteToFile

	JMP EndPrintMessage

FileErrorTerminate:
	MOV edx, OFFSET fileWriteError
	MOV ecx, SIZEOF fileWriteError
	call WriteString
	call WaitMsg
	exit								; exits program when encountering a file error

EndPrintMessage:
	POPAD
	RET


PrintMessageNumber ENDP



IntegerToString PROC


;CONVERTING NUMBER TO STRING THEN PRINTING TO FILE
	; clear previous results
	MOV edi, OFFSET tempStringNumber			; memory location to move bytes to
	MOV ecx, SIZEOF tempStringNumber			; number of characters to clear
	MOV al, 'x'									; value to move into memory location
	REP STOSB									; replaces byte in memory location edi with value of al, ecx number of times

	; sets registers to get number as string
	MOV eax, numberToWrite						; moves value into eax for use
	XOR edx, edx								; clears for remainder
	MOV ebx, 10									; DIV needs memory or registers, will store the value 10 to get the individual digits in base 10 values
	MOV ecx, SIZEOF tempStringNumber - 1		; Will set ecx counter to end of the string (zero-based indexing, so we subtract 1)

	; will take an intger and convert it into a string
StringToNumberLoop:
	cdq
	DIV ebx									; divides current number by 10 
	ADD edx, 30h								; remainder is converted into a string by adding an upper nibble to the digit
	MOV tempStringNumber[ecx], dl			; moves one byte from dl into the memory location. This is done in reverse to fix orientation of string 
	DEC ecx									; traverses string

	CMP eax, 0								; checks if quotient is zero
	JE EndStringToNumberLoop				; finished
	JMP StringToNumberLoop					; not done, loop back up

EndStringToNumberLoop:
	; tempString cleanup--> stringNumberToWrite

	; Clear previous result
	MOV edi, OFFSET stringNumberToWrite			; memory location to move bytes to
	MOV ecx, SIZEOF stringNumberToWrite			; number of characters to clear
	cld
	MOV al, 0									; value to move into memory location
	REP STOSB									; replaces byte in memory location edi with value of al, ecx number of times

; MOVE NEW VALUES into memory if NOT 'x'
	; clear previous values
	XOR eax, eax		; holds byte character
	XOR ebx, ebx		; holds index position for tempStringNumber
	XOR ecx, ecx		; holds counter for for stringNumberToWrite
LoopCopy:
	CMP ebx, SIZEOF tempStringNumber				; checks if has reached max size (zero-based indexing)
	JGE EndLoopCopy

	MOV al, BYTE PTR tempStringNumber[ebx]				; moves desired byte into al
	CMP al, 'x'											; check if 'x' exists
	JNE AddChar											; if not 'x' will copy to memory
	
	INC ebx
	JMP LoopCopy		; back to top
AddChar:
	MOV BYTE PTR stringNumberToWrite[ecx], al			; moves character into memory location according to ecx index

	INC ebx				; traverse position of stringNumberToWrite
	INC ecx				; traverse position of tempStringNumber. Only increments in addchar block
	JMP LoopCopy
EndLoopCopy:
	; must add null
	MOV charCountString, ecx							; saves length of string
	;MOV BYTE PTR stringNumberToWrite[ecx], NULL				; adds null immediately after last character in our stringNumber variable
	
	RET
IntegerToString ENDP







GetFileName PROC
	; transparancy
	PUSHAD
	
	; print file name prompt for user
	MOV edx, OFFSET promptOutputFile		; put memory reference in edx
	MOV ecx, SIZEOF promptOutputFile		; put size of bytes into prompt in ecx
	CALL WriteString

	; Receive keystrokes from user
	MOV edx, OFFSET fileName				; moves memory destination reference into edx
	MOV ecx, SIZEOF fileName				; put size of chars for filename into ecx (number to read)
	CALL ReadString							; receive the input
	CALL crlf

	; Opening the output file
	MOV edx, OFFSET fileName				; offset of filename used by CreateOutputFile routine call
	CALL CreateOutputFile					
	MOV outputFileHandle, eax				; moves output handler to eax
	CMP eax, INVALID_HANDLE_VALUE			; checks if error via pre-built constant
	JE OutputFileError						; Jmp to error block
	JMP Success								

OutputFileError:
	; print error message, then quit program
	MOV edx, OFFSET fileOpenError
	MOV ecx, SIZEOF fileWriteError
	CALL WriteString
	CALL WaitMsg							; pauses until key entry
	exit									; exit the program 

Success:
	; bytes are added to the file in print subroutines
	POPAD
	
	RET

GetFileName ENDP



GetInputFileName PROC
	; transparancy
	PUSHAD

	; print file name prompt for user
	MOV edx, OFFSET promptFileInput		; put memory reference in edx
	MOV ecx, SIZEOF promptFileInput		; put size of bytes into prompt in ecx
	CALL WriteString

	; Receive keystrokes from user
	MOV edx, OFFSET inputFileName				; moves memory destination reference into edx
	MOV ecx, SIZEOF inputFileName				; put size of chars for filename into ecx (number to read)
	CALL ReadString							; receive the input
	CALL crlf


	; Opening the input file
	MOV edx, OFFSET inputFileName				; offset of filename used by CreateOutputFile routine call
	CALL OpenInputFile					
	MOV inputFileHandle, eax				; moves output handler to eax
	CMP eax, INVALID_HANDLE_VALUE			; checks if error via pre-built constant
	JE InputFileError						; Jmp to error block
	JMP Success								

InputFileError:
	; print error message, then quit program
	MOV edx, OFFSET fileOpenError
	MOV ecx, SIZEOF fileOpenError
	CALL WriteString
	CALL Crlf
	CALL WaitMsg							; pauses until key entry
	STC										; indicates error to main
	JMP EndFileInput
	
Success:
	; bytes are added to the file in print subroutines
	CLC										; no error to main
EndFileInput:
	POPAD
	RET
GetInputFileName ENDP

getTopologyFromFile PROC
	; move the input from file into the 'buffer' memory for reference
	PUSHAD

	MOV edi, OFFSET buffer
	MOV ecx, bufferSize
	mov eax, 0
	cld
	REP STOSB

	MOV eax, inputFileHandle
	MOV edx, OFFSET buffer
	MOV ecx, bufferSize
	CALL ReadFromFile
	JC noInput

	; is there input in file?
	MOV byteCount, eax
	CMP eax, 0
	JLE noInput						; no input in designated file
	MOV buffer[eax], NULL
	JMP Success						; found input!

noInput:
	; prints error message and sets conditional flag to repeat input
	MOV edx, OFFSET msgNoInput
	MOV ecx, SIZEOF msgNoInput
	CALL WriteString
	CALL CRLF
	CALL WaitMsg
	STC
	JMP EndGetTopFile

Success:
	CLC
EndGetTopFile:
	POPAD
	RET

getTopologyFromFile ENDP

floatToString PROC

;CONVERTING NUMBER TO STRING THEN PRINTING TO FILE

	; obtain interger portion of real
	FLD realToString							; load floating point to top of stack
	FISTTP realIntegerPortion					; truncate top of stack, store as signed int, pop stack
	
	; Obtain fractional component of real
	FLD realToString							; places real to top of stack
	FISUB realIntegerPortion					; obtains fractional part of real
	
GetNextValue:
	
	; gets the fractional component as an integer
	FLD1							; 1 --> 1.0 on stack
	FADD							; adds 1 to the value to maintain leading zeros
	FIMUL tenThousand				; gets four decimal places (will throw away one, rounding)
	FISTTP realFractionPortion		; Stores truncated S(0) into memory, pops stack.
	
	; Return TOP pointer to S(0)
	FLDZ
	FLDZ

	; Checks last value in digit for rounding up or down
	MOV eax, realFractionPortion						; moves divisor into eax
	CDQ								; sign extend A --> D
	IDIV ten		; eax/realFractionPortion
	CMP EDX, 5
	JGE RoundUp

RoundDown:
	; nothing needs to be done here
	JMP ConvertToString
RoundUp:
	ADD realFractionPortion, 1

ConvertToString:

	; clear values from before
	MOV positionInString, 0 
	MOV edi, OFFSET completeFractionAsString
	MOV esi, OFFSET zero
	MOV ecx, SIZE_DECIMAL_STRING
	cld
	REP LODSB

	MOV edi, OFFSET numberToWrite
	MOV esi, OFFSET realIntegerPortion
	MOV ecx, SIZEOF realIntegerPortion
	cld
	REP MOVSB

	CALL IntegerToString
	MOV eax, charCountString
	MOV positionInString, eax				; will track index position

	; adding the integer to the string
	MOV edi, OFFSET completeFractionAsString			
	MOV esi, OFFSET stringNumberToWrite
	MOV ecx, positionInString
	cld
	REP MOVSB

	; adding the decimal to the string
	MOV edx, OFFSET completeFractionAsString				; adds memory location to edx
	ADD edx, positionInString								; adds oiffset into string
	MOV edi, edx											; moves offset with displacement into edi for processing
	MOV al, '.'												; adds ASCII decimal to al
	STOSB

	; updates position index
	ADD positionInString, 1

	; converts fractional part to string
	MOV edi, OFFSET numberToWrite
	MOV esi, OFFSET realFractionPortion
	MOV ecx, SIZEOF realFractionPortion
	cld
	REP MOVSB

	CALL IntegerToString

	; moves fractional portion of string into final product. Removes the leading one and removes the trailing 0
	MOV edx, OFFSET completeFractionAsString			
	ADD edx, positionInString							; adds offset into the string to edx
	MOV edi, edx											; moves to edi for processing
	MOV esi, OFFSET stringNumberToWrite
	ADD esi, 1
	MOV ecx, charCountString							; adds number of iterations to perform
	SUB ecx, 2											; removes unwanted trailing zero. 2 is required since added 1 to esi to skip leading 1
	cld
	REP MOVSB

	SUB positionInString, 2

	; TEST print completed string
	MOV edx, OFFSET completeFractionAsString
	MOV ecx, positionInString
	RET
floatToString ENDP



END main
