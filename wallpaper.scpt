FasdUAS 1.101.10   ��   ��    k             l      ��  ��   ��

Script by Philip Hutchison, April 2013
http://pipwerks.com
MIT license http://pipwerks.mit-license.org/

This script assumes:

1. You have a folder named "Wallpapers" in your Pictures folder
2. You have a subfolder named "Time of Day" in Wallpapers
3. You have six subfolders inside "Time of Day", with names that match the variables below. 
   * If you decide to use different folder names, you must change the variables to match the new folder names
4. You have images inside each folder

For example:
/Users/YOUR_USER_NAME/Pictures/Wallpapers/Time of Day/Afternoon Early/image.jpg

GeekTool can execute this script for you at specified intervals. Use this line in the command field:
osascript ~/Pictures/Wallpapers/Time\ of\ Day/wallpaper.scpt

     � 	 	� 
 
 S c r i p t   b y   P h i l i p   H u t c h i s o n ,   A p r i l   2 0 1 3 
 h t t p : / / p i p w e r k s . c o m 
 M I T   l i c e n s e   h t t p : / / p i p w e r k s . m i t - l i c e n s e . o r g / 
 
 T h i s   s c r i p t   a s s u m e s : 
 
 1 .   Y o u   h a v e   a   f o l d e r   n a m e d   " W a l l p a p e r s "   i n   y o u r   P i c t u r e s   f o l d e r 
 2 .   Y o u   h a v e   a   s u b f o l d e r   n a m e d   " T i m e   o f   D a y "   i n   W a l l p a p e r s 
 3 .   Y o u   h a v e   s i x   s u b f o l d e r s   i n s i d e   " T i m e   o f   D a y " ,   w i t h   n a m e s   t h a t   m a t c h   t h e   v a r i a b l e s   b e l o w .   
       *   I f   y o u   d e c i d e   t o   u s e   d i f f e r e n t   f o l d e r   n a m e s ,   y o u   m u s t   c h a n g e   t h e   v a r i a b l e s   t o   m a t c h   t h e   n e w   f o l d e r   n a m e s 
 4 .   Y o u   h a v e   i m a g e s   i n s i d e   e a c h   f o l d e r 
 
 F o r   e x a m p l e : 
 / U s e r s / Y O U R _ U S E R _ N A M E / P i c t u r e s / W a l l p a p e r s / T i m e   o f   D a y / A f t e r n o o n   E a r l y / i m a g e . j p g 
 
 G e e k T o o l   c a n   e x e c u t e   t h i s   s c r i p t   f o r   y o u   a t   s p e c i f i e d   i n t e r v a l s .   U s e   t h i s   l i n e   i n   t h e   c o m m a n d   f i e l d : 
 o s a s c r i p t   ~ / P i c t u r e s / W a l l p a p e r s / T i m e \   o f \   D a y / w a l l p a p e r . s c p t 
 
   
  
 l     ��������  ��  ��        l     ��������  ��  ��        l     ��  ��      BEGIN USER CONFIGURATION     �   2   B E G I N   U S E R   C O N F I G U R A T I O N      l     ��������  ��  ��        l     ��  ��      supply folder names     �   (   s u p p l y   f o l d e r   n a m e s      l     ����  r         m        �      M o r n i n g   E a r l y  o      ���� 0 morningearly morningEarly��  ��     ! " ! l    #���� # r     $ % $ m     & & � ' '  M o r n i n g   L a t e % o      ���� 0 morninglate morningLate��  ��   "  ( ) ( l    *���� * r     + , + m    	 - - � . .  A f t e r n o o n   E a r l y , o      ����  0 afternoonearly afternoonEarly��  ��   )  / 0 / l    1���� 1 r     2 3 2 m     4 4 � 5 5  A f t e r n o o n   L a t e 3 o      ���� 0 afternoonlate afternoonLate��  ��   0  6 7 6 l    8���� 8 r     9 : 9 m     ; ; � < <  E v e n i n g   E a r l y : o      ���� 0 eveningearly eveningEarly��  ��   7  = > = l    ?���� ? r     @ A @ m     B B � C C  E v e n i n g   L a t e A o      ���� 0 eveninglate eveningLate��  ��   >  D E D l     ��������  ��  ��   E  F G F l     �� H I��   H $  for multiple monitor support.    I � J J <   f o r   m u l t i p l e   m o n i t o r   s u p p o r t . G  K L K l     �� M N��   M i c set to true to display the same image on all desktops, false to show unique images on each desktop    N � O O �   s e t   t o   t r u e   t o   d i s p l a y   t h e   s a m e   i m a g e   o n   a l l   d e s k t o p s ,   f a l s e   t o   s h o w   u n i q u e   i m a g e s   o n   e a c h   d e s k t o p L  P Q P l    R���� R r     S T S m    ��
�� boovtrue T o      ���� <0 usesamepictureacrossdisplays useSamePictureAcrossDisplays��  ��   Q  U V U l     ��������  ��  ��   V  W X W l     �� Y Z��   Y   END USER CONFIGURATION    Z � [ [ .   E N D   U S E R   C O N F I G U R A T I O N X  \ ] \ l     ��������  ��  ��   ]  ^ _ ^ l     ��������  ��  ��   _  ` a ` l     ��������  ��  ��   a  b c b l     �� d e��   d   get current hour    e � f f "   g e t   c u r r e n t   h o u r c  g h g l   % i���� i r    % j k j n    # l m l 1   ! #��
�� 
hour m l   ! n���� n I   !������
�� .misccurdldt    ��� null��  ��  ��  ��   k o      ���� 0 h  ��  ��   h  o p o l     ��������  ��  ��   p  q r q l     �� s t��   s   set default periodOfDay    t � u u 0   s e t   d e f a u l t   p e r i o d O f D a y r  v w v l  & + x���� x r   & + y z y o   & '���� 0 morningearly morningEarly z o      ���� 0 periodofday periodOfDay��  ��   w  { | { l     ��������  ��  ��   |  } ~ } l     ��  ���    8 2 change value of periodOfDay based on current time    � � � � d   c h a n g e   v a l u e   o f   p e r i o d O f D a y   b a s e d   o n   c u r r e n t   t i m e ~  � � � l  , � ����� � Z   , � � � ��� � l  , = ����� � F   , = � � � ?   , 1 � � � o   , -���� 0 h   � m   - 0����  � A   4 9 � � � o   4 5���� 0 h   � m   5 8���� ��  ��   � r   @ E � � � o   @ A���� 0 morninglate morningLate � o      ���� 0 periodofday periodOfDay �  � � � l  H Y ����� � F   H Y � � � @   H M � � � o   H I���� 0 h   � m   I L����  � A   P U � � � o   P Q���� 0 h   � m   Q T���� ��  ��   �  � � � r   \ a � � � o   \ ]����  0 afternoonearly afternoonEarly � o      ���� 0 periodofday periodOfDay �  � � � l  d u ����� � F   d u � � � @   d i � � � o   d e���� 0 h   � m   e h����  � A   l q � � � o   l m���� 0 h   � m   m p���� ��  ��   �  � � � r   x } � � � o   x y���� 0 afternoonlate afternoonLate � o      ���� 0 periodofday periodOfDay �  � � � l  � � ����� � F   � � � � � @   � � � � � o   � ����� 0 h   � m   � �����  � A   � � � � � o   � ����� 0 h   � m   � ����� ��  ��   �  � � � r   � � � � � o   � ����� 0 eveningearly eveningEarly � o      ���� 0 periodofday periodOfDay �  � � � l  � � ����� � G   � � � � � @   � � � � � o   � ����� 0 h   � m   � �����  � A   � � � � � o   � ����� 0 h   � m   � ����� ��  ��   �  ��� � r   � � � � � o   � ����� 0 eveninglate eveningLate � o      ���� 0 periodofday periodOfDay��  ��  ��  ��   �  � � � l     ��������  ��  ��   �  � � � l     �� � ���   � ; 5 helper function ("handler") for getting random image    � � � � j   h e l p e r   f u n c t i o n   ( " h a n d l e r " )   f o r   g e t t i n g   r a n d o m   i m a g e �  � � � i      � � � I      �� ����� 0 getimage getImage �  ��� � o      ���� 0 
foldername 
folderName��  ��   � k      � �  � � � l     ����~��  �  �~   �  � � � O      � � � L     � � c     � � � n     � � � 3    �}
�} 
file � n     � � � 4    �| �
�| 
cfol � l    ��{�z � b     � � � m    	 � � � � � @ P i c t u r e s : W a l l p a p e r s : T i m e   o f   D a y : � o   	 
�y�y 0 
foldername 
folderName�{  �z   � 1    �x
�x 
home � m    �w
�w 
ctxt � m      � ��                                                                                  MACS  alis    B  Macintosh SSD                  BD ����
Finder.app                                                     ����            ����  
 cu             CoreServices  )/:System:Library:CoreServices:Finder.app/    
 F i n d e r . a p p    M a c i n t o s h   S S D  &System/Library/CoreServices/Finder.app  / ��   �  ��v � l   �u�t�s�u  �t  �s  �v   �  � � � l     �r�q�p�r  �q  �p   �  � � � l     �o�n�m�o  �n  �m   �  � � � l  �T ��l�k � O   �T � � � k   �S � �  � � � l  � ��j�i�h�j  �i  �h   �  � � � l  � ��g � ��g   � 3 - wrapped in a try block for error suppression    � � � � Z   w r a p p e d   i n   a   t r y   b l o c k   f o r   e r r o r   s u p p r e s s i o n �  � � � Q   �Q � ��f � k   �H � �  � � � l  � ��e�d�c�e  �d  �c   �  �  � l  � ��b�b   6 0 determine which picture to use for main display    � `   d e t e r m i n e   w h i c h   p i c t u r e   t o   u s e   f o r   m a i n   d i s p l a y   r   � � n  � �	 I   � ��a
�`�a 0 getimage getImage
 �_ o   � ��^�^ 0 periodofday periodOfDay�_  �`  	  f   � � o      �]�] (0 maindisplaypicture mainDisplayPicture  l  � ��\�[�Z�\  �[  �Z    l  � ��Y�Y   = 7 set the picture for additional monitors, if applicable    � n   s e t   t h e   p i c t u r e   f o r   a d d i t i o n a l   m o n i t o r s ,   i f   a p p l i c a b l e  O   �< k   �;  l  � ��X�W�V�X  �W  �V    l  � ��U�U   &   get a reference to all desktops    � @   g e t   a   r e f e r e n c e   t o   a l l   d e s k t o p s   r   � �!"! N   � �## 2   � ��T
�T 
dskp" o      �S�S 0 thedesktops theDesktops  $%$ l  � ��R�Q�P�R  �Q  �P  % &'& l  � ��O()�O  ( !  handle additional desktops   ) �** 6   h a n d l e   a d d i t i o n a l   d e s k t o p s' +,+ Z   �9-.�N�M- l  � �/�L�K/ ?   � �010 l  � �2�J�I2 I  � ��H3�G
�H .corecnte****       ****3 o   � ��F�F 0 thedesktops theDesktops�G  �J  �I  1 m   � ��E�E �L  �K  . k   �544 565 l  � ��D�C�B�D  �C  �B  6 787 l  � ��A9:�A  9 D > loop through all desktops (beginning with the second desktop)   : �;; |   l o o p   t h r o u g h   a l l   d e s k t o p s   ( b e g i n n i n g   w i t h   t h e   s e c o n d   d e s k t o p )8 <=< Y   �3>�@?@�?> k   �.AA BCB l  � ��>�=�<�>  �=  �<  C DED l  � ��;FG�;  F #  determine which image to use   G �HH :   d e t e r m i n e   w h i c h   i m a g e   t o   u s eE IJI Z   �KL�:MK l  � N�9�8N =  � OPO o   � ��7�7 <0 usesamepictureacrossdisplays useSamePictureAcrossDisplaysP m   � ��6
�6 boovfals�9  �8  L r  QRQ n STS I  �5U�4�5 0 getimage getImageU V�3V o  �2�2 0 periodofday periodOfDay�3  �4  T  f  R o      �1�1 20 secondarydisplaypicture secondaryDisplayPicture�:  M r  WXW n YZY o  �0�0 (0 maindisplaypicture mainDisplayPictureZ  f  X o      �/�/ 20 secondarydisplaypicture secondaryDisplayPictureJ [\[ l �.�-�,�.  �-  �,  \ ]^] l �+_`�+  _   apply image to desktop   ` �aa .   a p p l y   i m a g e   t o   d e s k t o p^ bcb r  ,ded o  �*�* 20 secondarydisplaypicture secondaryDisplayPicturee n      fgf 1  '+�)
�) 
picPg n  'hih 4  "'�(j
�( 
cobjj o  %&�'�' 0 x  i l "k�&�%k o  "�$�$ 0 thedesktops theDesktops�&  �%  c l�#l l --�"�!� �"  �!  �   �#  �@ 0 x  ? m   � ��� @ l  � �m��m I  � ��n�
� .corecnte****       ****n o   � ��� 0 thedesktops theDesktops�  �  �  �?  = o�o l 44����  �  �  �  �N  �M  , p�p l ::����  �  �  �   m   � �qq�                                                                                  sevs  alis    ^  Macintosh SSD                  BD ����System Events.app                                              ����            ����  
 cu             CoreServices  0/:System:Library:CoreServices:System Events.app/  $  S y s t e m   E v e n t s . a p p    M a c i n t o s h   S S D  -System/Library/CoreServices/System Events.app   / ��   rsr l ==����  �  �  s tut l ==�vw�  v ( " set the primary monitor's picture   w �xx D   s e t   t h e   p r i m a r y   m o n i t o r ' s   p i c t u r eu yzy l ==�{|�  { R L due to a Finder quirk, this has to be done AFTER setting the other displays   | �}} �   d u e   t o   a   F i n d e r   q u i r k ,   t h i s   h a s   t o   b e   d o n e   A F T E R   s e t t i n g   t h e   o t h e r   d i s p l a y sz ~~ r  =F��� o  =@�� (0 maindisplaypicture mainDisplayPicture� 1  @E�
� 
dpic ��
� l GG�	���	  �  �  �
   � R      ���
� .ascrerr ****      � ****�  �  �f   � ��� l RR��� �  �  �   �   � m   � ����                                                                                  MACS  alis    B  Macintosh SSD                  BD ����
Finder.app                                                     ����            ����  
 cu             CoreServices  )/:System:Library:CoreServices:Finder.app/    
 F i n d e r . a p p    M a c i n t o s h   S S D  &System/Library/CoreServices/Finder.app  / ��  �l  �k   � ���� l     ��������  ��  ��  ��       �����  & - 4 ; B���� 4����������  � ���������������������������������� 0 getimage getImage
�� .aevtoappnull  �   � ****�� 0 morningearly morningEarly�� 0 morninglate morningLate��  0 afternoonearly afternoonEarly�� 0 afternoonlate afternoonLate�� 0 eveningearly eveningEarly�� 0 eveninglate eveningLate�� <0 usesamepictureacrossdisplays useSamePictureAcrossDisplays�� 0 h  �� 0 periodofday periodOfDay�� (0 maindisplaypicture mainDisplayPicture�� 0 thedesktops theDesktops��  ��  ��  � �� ����������� 0 getimage getImage�� ����� �  ���� 0 
foldername 
folderName��  � ���� 0 
foldername 
folderName�  ����� �����
�� 
home
�� 
cfol
�� 
file
�� 
ctxt�� � *�,��%/�.�&UOP� �����������
�� .aevtoappnull  �   � ****� k    T��  ��  !��  (��  /��  6��  =��  P��  g��  v��  ���  �����  ��  ��  � ���� 0 x  � $ �� &�� -�� 4�� ;�� B�����������������������������q�������������������� 0 morningearly morningEarly�� 0 morninglate morningLate��  0 afternoonearly afternoonEarly�� 0 afternoonlate afternoonLate�� 0 eveningearly eveningEarly�� 0 eveninglate eveningLate�� <0 usesamepictureacrossdisplays useSamePictureAcrossDisplays
�� .misccurdldt    ��� null
�� 
hour�� 0 h  �� 0 periodofday periodOfDay�� �� 
�� 
bool�� �� �� �� 0 getimage getImage�� (0 maindisplaypicture mainDisplayPicture
�� 
dskp�� 0 thedesktops theDesktops
�� .corecnte****       ****�� 20 secondarydisplaypicture secondaryDisplayPicture
�� 
cobj
�� 
picP
�� 
dpic��  ��  ��U�E�O�E�O�E�O�E�O�E�O�E�OeE�O*j �,E�O�E` O�a 	 �a a & 
�E` Y s�a 	 �a a & 
�E` Y W�a 	 �a a & 
�E` Y ;�a 	 �a a & 
�E` Y �a 
 �a a & 
�E` Y hOa  � �)_ k+ E` Oa  g*a -E` O_ j k M El_ j kh  �f  )_ k+ E` Y )a ,E` O_ _ a �/a  ,FOP[OY��OPY hOPUO_ *a !,FOPW X " #hOPU
�� boovtrue�� � ��� � M a c i n t o s h   S S D : U s e r s : h e r o n : P i c t u r e s : W a l l p a p e r s : T i m e   o f   D a y : A f t e r n o o n   L a t e : l a t e - a f t e r n o o n . p n g� �� q��
�� 
dskp��  ��  ��   ascr  ��ޭ