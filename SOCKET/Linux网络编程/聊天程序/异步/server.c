
#include<stdio.h>
#include<stdlib.h>
#include<string.h>
#include<errno.h>
#include<sys/socket.h>
#include<arpa/inet.h>
#include<netinet/in.h>
#include<sys/types.h>
#include<unistd.h>
#include<sys/time.h>

//#define BUFLEN 10
#define BUFLEN 1024

int main(int argc,char **argv)
{
  int sockfd,newfd;
  struct sockaddr_in s_addr,c_addr;
  char buf[BUFLEN];
  socklen_t len;
  unsigned int port,listnum;
  fd_set rfds;
  struct timeval tv;
  int retval,maxfd;

  //建立socket
  if((sockfd = socket(AF_INET,SOCK_STREAM,0)) == -1){
    perror("socket");
    exit(errno);
  }else
    printf("socket create success!\n");

  //设置服务器端口
  if(argv[2])
    port = atoi(argv[2]);
  else
    port = 4567;

  //设置侦听队列长度
  if(argv[3])
    listnum = atoi(argv[3]);
  else
    listnum = 3;

  //设置服务器ip
  bzero(&s_addr,sizeof(s_addr));
  s_addr.sin_family = AF_INET;
  s_addr.sin_port = htons(port);
  if(argv[1])
    s_addr.sin_addr.s_addr = inet_addr(argv[1]);
  else
    s_addr.sin_addr.s_addr = INADDR_ANY;

  //把地址和端口绑定到套接字上
  if((bind(sockfd,(struct sockaddr*)&s_addr,sizeof(struct sockaddr))) == -1){
    perror("bind");
    exit(errno);
  }else
    printf("bind success!\n");

  //侦听本地端口
  if(listen(sockfd,listnum) == -1){
    perror("listen");
    exit(errno);
  }else
    printf("the server is listening!\n");
  while(1){
    printf("*******************聊天开始*******************\n");
    len = sizeof(struct sockaddr);
    if((newfd = accept(sockfd,(struct sockaddr*)&c_addr,&len)) == -1){
      perror("accept");
        exit(errno);
    }else
      printf("正在与您聊天的客户端是：%s:%d\n",inet_ntoa(c_addr.sin_addr),ntohs(c_addr.sin_port));
    while(1){
      //把可读文件描述符的集合清空
      FD_ZERO(&rfds);
      //把标准输入的文件描述符加入到集合中
      FD_SET(0,&rfds);
      maxfd = 0;
      //把当前连接的文件描述符加入到集合中
      FD_SET(newfd,&rfds);
      //找出文件描述符集合中最大的文件描述符
      if(maxfd < newfd)
        maxfd = newfd;
      //设置超时时间
      tv.tv_sec = 5;
      tv.tv_usec = 0;
      //等待聊天
      retval = select(maxfd+1,&rfds,NULL,NULL,&tv);
      if(retval == -1){
        printf("select出错，与该客户端连接的程序退出\n");
        break;
      }else if(retval == 0){
        printf("服务器没有任何输入信息，并且客户端也没有信息到来，waiting...\n");
        continue;
      }else{
        //用户输入信息了，开始处理信息并发送
        if(FD_ISSET(0,&rfds)){
        _retry:
              //************发送消息***********
              bzero(buf,BUFLEN);
              printf("请输入发送给对方的消息：");
              //fgets函数：从流中读取BUFLEN-1个字符
              fgets(buf,BUFLEN,stdin);
              //打印发送的消息
              //fputs(buf,stdout);
              if(!strncasecmp(buf,"quit",4)){
                printf("server请求终止聊天！\n");
                break;
              }
              //如果输入的字符串只有"\n"，即回车，那么请重新输入
              if(!strncasecmp(buf,"\n",1)){
                printf("输入的字符只有回车，这个是不正确的！！\n");
                goto _retry;
              }
              //如果buf中含有'\n'，那么要用strlen(buf)-1，去掉'\n'
              if(strchr(buf,'\n'))
                len = send(newfd,buf,strlen(buf)-1,0);
              //如果buf中没有'\n'，则用buf的真正长度strlen(buf)
              else
                len = send(newfd,buf,strlen(buf),0);
              if(len > 0)
                printf("\t消息发送成功，本次共发送的字节数是共发送的字节数是：%d\n",len);
              else{
                printf("消息发送失败！\n");
                break;
              }
        }
        if(FD_ISSET(newfd,&rfds)){
              //接收消息
              bzero(buf,BUFLEN);
              len = recv(newfd,buf,BUFLEN,0);
              if(len > 0)
                printf("客户端发来的信息是：%s，共有字节数是：%d\n",buf,len);
              else{
                if(len < 0)
                  printf("接收信息失败！\n");
                else
                  printf("客户端退出了，聊天终止！\n");
                break;
              }
        }
      }
    }
    //关闭聊天的套接字
    close(newfd);
    //是否退出服务器
    printf("服务器是否退出程序：y->是；n->否？");
    bzero(buf,BUFLEN);
    fgets(buf,BUFLEN,stdin);
    if(!strncasecmp(buf,"y",1)){
      printf("server退出！\n");
      break;
    }
  }
  //关闭服务器的套接字
  close(sockfd);
  return 0;
}
