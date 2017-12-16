#!/bin/bash

catUuid=0
tagId=0

#Strip all leading and trailing spaces
function trim() {
    local trimmed="$1"

    # Strip leading spaces.
    while [[ $trimmed == ' '* ]]; do
       trimmed="${trimmed## }"
    done
    # Strip trailing spaces.
    while [[ $trimmed == *' ' ]]; do
        trimmed="${trimmed%% }"
    done

    echo "$trimmed"
}

#插入一个分类 && 获取序号
#$1 分类名称			必选
#$2 父分类的uuid		可选
function insertNewCatAndGetSeq() {
	
	catName=$1
	parentCatUuid=$2
	
	if [ -z "${catName}" ]
	then
		catUuid=${topCatUuid}
		return;
	fi
	
	if [ -z "${parentCatUuid}" ]
	then
		catUuid=$(sqlite3 ${mWebDb} "select uuid from cat where name='${catName}'")
		pid=0
	else
		catUuid=$(sqlite3 ${mWebDb} "select uuid from cat where name='${catName}' and pid=${parentCatUuid}")
		pid=${parentCatUuid}
	fi
	
	if [ -n "${catUuid}" ]
	then
		echo "分类已存在，不再创建"
		echo "catUuid=${catUuid}"
		return
	fi
	
	currentCatSeq=$(sqlite3 ${mWebDb} "select seq from sqlite_sequence where name='cat'")
	newCatSeq=$((currentCatSeq+1))
	echo "newCatSeq=${newCatSeq}"
	
	sqlite3 ${mWebDb} "update sqlite_sequence set seq=${newCatSeq} where name='cat'"
	
	currentSortSeq=$(sqlite3 ${mWebDb} "select max(sort) from cat")
	newSortSeq=$((currentSortSeq+1))
	echo "newSortSeq=${newSortSeq}"
	
	uuid=`gdate +%s%N | cut -c1-14`

	
	sqlite3 ${mWebDb} "insert into cat(id, pid, uuid, name, docName, catType, sort, sortType, siteURL, siteSkinName, siteLastBuildDate, siteBuildPath, siteFavicon, siteLogo, siteDateFormat, sitePageSize, siteListTextNum, siteName, siteDes, siteShareCode, siteHeader, siteOther, siteMainMenuData, siteExtDef, siteExtValue, sitePostExtDef, siteEnableLaTeX, siteEnableChart) values(${newCatSeq}, ${pid}, ${uuid}, '${catName}', '', 12, ${newSortSeq}, 0, '', '', 0, '', '', '', '', 0, 0, '', '', '', '', '', '', '', '', '', 0, 0)"
	echo "新分类已创建"
	
	catUuid=$(sqlite3 ${mWebDb} "select uuid from cat where name='${catName}'" | sed -n '1p')
	echo "catUuid=${catUuid}"
}

#插入一个tag && 获取序号
function insertNewTagAndGetSeq() {
	
	tagId=$(sqlite3 ${mWebDb} "select id from tag where name='${tagName}'")
	
	if [ -n "${tagId}" ]
	then
		echo "Tag已存在，不再创建"
		echo "tagId=${tagId}"
		return
	fi
	
	currentTagSeq=$(sqlite3 ${mWebDb} "select seq from sqlite_sequence where name='tag'")
	newTagSeq=$((currentTagSeq+1))
	echo "newTagSeq=${newTagSeq}"
	
	sqlite3 ${mWebDb} "update sqlite_sequence set seq=${newTagSeq} where name='${tagName}'"

	sqlite3 ${mWebDb} "insert into tag(id, name) values(${newTagSeq}, '${tagName}')"
	
	tagId=$(sqlite3 ${mWebDb} "select id from tag where name='${tagName}'" | sed -n '1p')
	echo "tagId=${tagId}"
}

#插入新文章
function insertNewArticle() {
	
	aid=$1
	
	currentSeq=$(sqlite3 ${mWebDb} "select seq from sqlite_sequence where name='article'")
	newSeq=$((currentSeq+1))
	echo "currentSeq=${currentSeq}"
	dateAddModify=$(echo ${aid} | cut -c1-10)
	
	sqlite3 ${mWebDb} "update sqlite_sequence set seq=${newSeq} where name='article'"
	
	sqlite3 ${mWebDb} "insert into article(id, uuid, type, state, sort, dateAdd, dateModif, dateArt, docName, otherMedia, buildResource, postExtValue) values(${newSeq}, ${aid}, 0, 1, ${aid}, ${dateAddModify}, ${dateAddModify}, ${dateAddModify}, '', '', '', '')"
}

#设置文章分类
#$1 articleId
#$2 categoryUuid
function insertNewCatArticle() {
	
	aid=$1
	catUuid=$2
	
	currentSeq=$(sqlite3 ${mWebDb} "select seq from sqlite_sequence where name='cat_article'")
	newSeq=$((currentSeq+1))
	echo "currentSeq=${currentSeq}"
	
	sqlite3 ${mWebDb} "update sqlite_sequence set seq=${newSeq} where name='cat_article'"
	
	sqlite3 ${mWebDb} "insert into cat_article(id, rid, aid) values(${newSeq}, ${catUuid}, ${aid})"
}

#设置文章tag
function insertNewTagArticle() {
	
	aid=$1
	
	currentSeq=$(sqlite3 ${mWebDb} "select seq from sqlite_sequence where name='tag_article'")
	newSeq=$((currentSeq+1))
	echo "currentSeq=${currentSeq}"
	
	sqlite3 ${mWebDb} "update sqlite_sequence set seq=${newSeq} where name='tag_article'"
	
	sqlite3 ${mWebDb} "insert into tag_article(id, rid, aid) values(${newSeq}, ${tagId}, ${aid})"
}

#脚本入参
hexoSrcDir=/Users/chenzz/blog/source/_posts
mWebBase=/Users/chenzz/Documents/MWeb/mainlib
#mWebBase=/Users/chenzz/Downloads/mainlib
mWebDocsDir=${mWebBase}/docs
mWebDb=${mWebBase}/mainlib.db
userInputCatName="我的博客"
#tagName="blog"

##reset 测试数据
#echo "reseting test date..."
#rm -rf ${mWebBase}
#cp -r /Users/chenzz/Documents/MWeb/mainlib ${mWebBase}


#创建目录和Tag
cd ${mWebDocsDir}
echo "inserting cat and tag..."
insertNewCatAndGetSeq "${userInputCatName}"
#insertNewTagAndGetSeq

topCatUuid=${catUuid}


cd ${hexoSrcDir}

for file in *
do
	dateStr=$(cat "${file}" | grep 'date:' | sed -n '1p' | awk -F ' ' '{print $2" "$3}' )
	newFileName="$(gdate --date="${dateStr}" +"%s")0000"
	
	#parse title
	title=$(cat "${file}" | grep 'title:' | sed -n '1p' | awk -F '"' '{print $2}' )
	if [ -z "${title}" ]
	then
		title=$(cat "${file}" | grep 'title:' | sed -n '1p' | awk -F ' ' '{print $2}' )	
	fi
	echo "title is: ${title}"
	
	#parse category
	category=$(cat "${file}" | grep 'categories:' | sed -n '1p' | awk -F ' ' '{print $2}' )
	if [ -z "${category}" ]
	then
		category=$(cat "${file}" | grep 'categories:' | sed -n '1p' | awk -F ':' '{print $2}' )	
	fi
	category=$(trim $category)
	echo "category is: ${category}"
	
	echo "inserting sub cat..."
	insertNewCatAndGetSeq "${category}" ${topCatUuid}
	
#	#parse tags
#	tagsStr=$(cat "${file}" | grep 'tags:' | sed -n '1p' | awk -F ':' '{print $2}' )
#	echo "tagsStr is: ${tagsStr}"
#	if [ -n "${tagsStr}" ]
#	then
#		tagsStr=${tagsStr:1: -1}
#		IFS=', '
#		ary=($str)
#	fi
#	echo "tags is: ${ary[@]}"
	
	echo "copying ${file} to ${mWebDocsDir}/${newFileName}.md"	
	cp "${file}" ${mWebDocsDir}/${newFileName}.md
	
	echo "deleting 1-8 line of file..."
	gsed -i "1,8d" "${mWebDocsDir}/${newFileName}.md"
	
	echo "inserting the title..."
	gsed -i "1i${title}" "${mWebDocsDir}/${newFileName}.md"
	
	echo "inserting the toc..."
	gsed -i "2i\ " "${mWebDocsDir}/${newFileName}.md"
	gsed -i "3i[TOC]" "${mWebDocsDir}/${newFileName}.md"
	gsed -i "4i\ " "${mWebDocsDir}/${newFileName}.md"
	
	insertNewArticle ${newFileName} ${title}
	insertNewCatArticle ${newFileName} ${catUuid}
#	insertNewTagArticle ${newFileName}
done


