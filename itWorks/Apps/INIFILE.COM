�6��������             ��������             
INIFILE 1.2 (c) 2003, Horst Schaeffer
Add/Change/Remove/Read entries in INI files
Syntax:
Add or Change:
  INIFILE ini_file_name [section] item=ini_string
Remove:
  INIFILE ini_file_name [section] item=
  INIFILE ini_file_name [section] /remove
Read:
  INIFILE ini_file_name [section] item
    (generates a SET statement to STDOUT)
  INIFILE ini_file_name [section]
    (generates SET statements for all items in section)

For INI files without sections: specify an empty section
 <w<ar<zw$��S�  :�u����� tC��r�[�+ۊ����Ċ ���:�uC:�u����=u< uC�8 t��8=t	���u:�u�0��ì< t�N�<t�< t�<[t��� �ì< t�<,t�N�<[t�ÿ+�<t��<]u�� ��� �< t�N<"uF�Ĭ< t�N�{�<t8$t�<=t����{v	�}� uO��< t�N<=t:�uF����{u���= �êF�< t�N+ɀ<t	8$t�A��F�}� uO��� ���u��É�+ɬA��u�I� �@�!�*��  
 *�o��+�8$tAF���m�@�!s���� ���<t��<u��<
uFþ��+�=[]t)�< t�N<[u�]�������t�<u���6��6�ÿ{�==t�>�u�6�É6��< t�N<[t<t�=�D�����u��	���6��6��set � � � �@�!�{��u�6��׀<t�<t��� �+ɉ׀= tGA��� �@�!�o� � �@�!Ë6��< t�N<t�6�����t���<t�<[u�Ë6��6��< t�N<[t	<t�����À>+ t���u�6��< t�<t�<
t�N<[t<u׋6����t�N�< t�<t�<
t�<]u����t	�|�tN��<
uF�6�Ë6�����)у�r�|�
u�|�
u�������t�|�
t����+ɋm*��B�!���t�	���t��u����+*��������{*�������Ë6��< t�<t�<
t�N�<t�<[uV���^�����.*����INIFILE syntax error INI file not found INI file over 60Kb Cannot make file Cannot write file file read error    /remove��� �< t�N<t�</?u�-���{�2��K�r(�< t�N</u�1�����u����P��< t�N<t��������t� �{���=�!��r$�m�����ش?�!s���;�u��������u+ɴ<�!s���v��m�������t����t����u����u�L��{���X��m�>�!�L�*�! 