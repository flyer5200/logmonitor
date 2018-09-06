#分布式日志收集系统解决方案

create By `lc` at `2015-05-15`
本文档采用[MarkdownPad 2](http://markdownpad.com/)编写, [Markdown 语法说明 ](http://wowubuntu.com/markdown/)

###前言

系统一大，就会拆分成多个独立的进程，比如web+wcf/web api等，也就成了分布式系统。
要看一个请求怎么从头到尾走的，就有些困难了，要是进行DEBUG、跟踪，就更加麻烦了，困难程度要视进程多少而定，越多越复杂。分布式日志收集系统就登场了。

开源日志收集、展示系统 - logstash+kibana+ElasticSearch+Redis/RabbitMQ

######基本架构图:

![](http://nkcoder.github.io/images/post/ELKR-log-platform.jpg)

* 里面虽然是Redis，但是没关系，换成RabbitMQ照样行, 可以搭配haproxy+keepalived来实现redis的高可用
* 这个Broker Redis/RabbitMQ去掉实际上也行，只是去掉会会造成高峰时刻拖垮ElasticSearch，此处出现的目的是削平峰谷
* Shipper Logstash图中有3个，意思是可以有多个，可以分布在不同Server上，无论是windows还是linux系统都可以
* 关于这个架构的扩展性，具体可看
* <http://logstash.net/docs/1.5.0/>
* <http://nkcoder.github.io/blog/20141031/elkr-log-platform-deploy/>
