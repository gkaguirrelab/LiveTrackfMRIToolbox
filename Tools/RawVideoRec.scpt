FasdUAS 1.101.10   ��   ��    k             l     ��  ��    [ U This script records video via the ezcap VideoCapture software. To launch the script:     � 	 	 �   T h i s   s c r i p t   r e c o r d s   v i d e o   v i a   t h e   e z c a p   V i d e o C a p t u r e   s o f t w a r e .   T o   l a u n c h   t h e   s c r i p t :   
  
 l     ��������  ��  ��        l     ��  ��    [ U from terminal  osascript /path/to/script/RawVideoRec.scpt savePath vidName recLength     �   �   f r o m   t e r m i n a l     o s a s c r i p t   / p a t h / t o / s c r i p t / R a w V i d e o R e c . s c p t   s a v e P a t h   v i d N a m e   r e c L e n g t h      l     ��������  ��  ��        l     ��  ��    � � from matlab  system(sprintf('osascript /path/to/script/RawVideoRec.scpt %s %s %s', savePath, vidName1, num2str(recTime+postBufferTime)));     �     f r o m   m a t l a b     s y s t e m ( s p r i n t f ( ' o s a s c r i p t   / p a t h / t o / s c r i p t / R a w V i d e o R e c . s c p t   % s   % s   % s ' ,   s a v e P a t h ,   v i d N a m e 1 ,   n u m 2 s t r ( r e c T i m e + p o s t B u f f e r T i m e ) ) ) ;      l     ��������  ��  ��        i         I     �� ��
�� .aevtoappnull  �   � ****  o      ���� 0 argv  ��    k     +      !   O     ) " # " k    ( $ $  % & % I   �� '��
�� .aevtodocnull  �    alis ' 4    �� (
�� 
cwin ( m     ) ) � * * $ e z c a p   V i d e o G r a b b e r��   &  +�� + I   (���� ,
�� .efxcStarnull��� ��� null��   , �� - .
�� 
kWch - m     / / � 0 0 $ e z c a p   V i d e o G r a b b e r . �� 1 2
�� 
kFil 1 4    �� 3
�� 
psxf 3 l    4���� 4 b     5 6 5 b     7 8 7 n     9 : 9 4    �� ;
�� 
cobj ; m    ����  : o    ���� 0 argv   8 n     < = < 4    �� >
�� 
cobj > m    ����  = o    ���� 0 argv   6 m     ? ? � @ @  . m o v��  ��   2 �� A��
�� 
kDur A n     $ B C B 4   ! $�� D
�� 
cobj D m   " #����  C o     !���� 0 argv  ��  ��   # m      E E                                                                                      @ alis    �  Macintosh HD               �A'�H+   �}Qezcap VideoCapture.app                                          �}R��        ����  	                ezcap VideoGrabber    �Am�      ��JZ     �}Q ��I  EMacintosh HD:Applications: ezcap VideoGrabber: ezcap VideoCapture.app   .  e z c a p   V i d e o C a p t u r e . a p p    M a c i n t o s h   H D  6Applications/ezcap VideoGrabber/ezcap VideoCapture.app  / ��   !  F�� F l  * *��������  ��  ��  ��     G�� G l     ��������  ��  ��  ��       �� H I��   H ��
�� .aevtoappnull  �   � **** I �� ���� J K��
�� .aevtoappnull  �   � ****�� 0 argv  ��   J ���� 0 argv   K  E�� )���� /������ ?������
�� 
cwin
�� .aevtodocnull  �    alis
�� 
kWch
�� 
kFil
�� 
psxf
�� 
cobj
�� 
kDur�� 
�� .efxcStarnull��� ��� null�� ,� &*��/j O*���*��k/��l/%�%/��m/� UOP ascr  ��ޭ