# mweb-hexo-importer
把Hexo文档批量导入到MWeb中

## 1、导入效果
![-w200](https://raw.githubusercontent.com/chenzz/static-resource/master/1122CBEF-358F-4F80-AF64-5A56C5938248.png)

## 2、具体需求

遍历每个hexo文档，进行以下处理：

* 复制文档到MWeb的文档库中
* 在MWeb的DB中插入该文档
* 解析头部信息中的创建时间，转换为时间戳作为文件名
* 解析头部信息中的创建时间，插入数据库作为该问文档的创建时间
* 解析头部信息中的Title，插入在文档第一行中
* 删除Hexo特有的头部信息
* 创建『我的博客』分类
* 所有导入文档加入『我的博客』分类下
* 解析文章中的分类信息，在『我的博客』分类下创建二级分类
* 文档加入对应的二级分类
* 文档第二行插入`[TOC]`

## 3、使用方法

* 备份MWeb文档（缺省路径为`~/Library/Containers/com.coderforart.MWeb/Data/Documents/mainlib`）
* 修改脚本中的`hexoSrcDir`变量为hexo的_post文件夹
* 修改脚本中的`mWebBase`变量为MWeb的文档文件夹
* 运行命令`bash import.sh`

