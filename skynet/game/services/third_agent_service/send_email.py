# coding=utf-8
#-*- coding: UTF-8 -*- 
import os
import sys
import smtplib
import string
import socket
from email.mime.text import MIMEText
from email.mime.multipart import MIMEMultipart
from email.mime.image import MIMEImage
from email.mime.application import MIMEApplication
from smtplib import SMTP_SSL
from email.header import Header 
#path
argv_0=sys.argv[0] 

#接收方
to_mail_str=sys.argv[1]
#标题
_subject=sys.argv[2]
#内容
_context=sys.argv[3]

to_mail_array=to_mail_str.split(",")

from_mail='jytz@jingyuhudong.club'

msg=MIMEMultipart()
msg['From']=from_mail
msg['To']=to_mail_str
msg['Subject']=_subject

msg.attach(MIMEText(_context,'html','utf-8'))

# 暂不支持附件
# attac=MIMEApplication(file(zipPath,'rb').read())
# attac['Content-Type']='application/octet-stream'
# attac.add_header('content-disposition','attachment',filename=argv_3)
# msg.attach(attac)

server=smtplib.SMTP_SSL('smtp.exmail.qq.com')
server.ehlo('smtp.exmail.qq.com')
server.login(from_mail,'Asd1314520')
server.sendmail(from_mail,to_mail_array,msg.as_string())
server.quit()

