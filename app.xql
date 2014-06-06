xquery version "3.0";
(:acer localhost:)
module namespace app="http://exist-db.org/apps/cxd/templates";

import module namespace templates="http://exist-db.org/xquery/templates" ;
import module namespace config="http://exist-db.org/apps/cxd/config" at "config.xqm";
import module namespace xmldb="http://exist-db.org/xquery/xmldb";
import module namespace functx = "http://www.functx.com" at "functx.xql";
declare namespace tei="http://www.tei-c.org/ns/1.0";

declare function app:cat-list($node as node()) as node(){
let $result:=
    if (exists($node/tei:category)) then
        <ul class="dropdown-toggle">
            <a href="#" class="dropdown-toggle" data-toggle="dropdown" style="color:white">{$node/tei:catDesc/text()}</a>
            app:cat-list($node/tei:category)
        </ul>
    else
        <ul>
            <li>{$node/tei:catDesc}[{$node/@xml:id/text()}]</li>
        </ul>
return
    $result
};
declare function app:title-all($node as node(), $model as map(*)){
let $log-in:=xmldb:login($config:data-root,"admin","kaijun2chen")
let $create-collection := xmldb:create-collection($config:data-root, "output")
for $i in 1 to 361
let $data:=doc($config:data-root||"/qsw/"||app:addzero(xs:string($i),3)||".xml")
let $title:=$data//tei:text//tei:div/tei:p/tei:title
let $table:=
            <div>{
                    for $p in $title
                    let $pp:=
                        if (exists($p/ancestor::tei:div[5])) then
                            <span>{$p/text()}##{substring-after(data($p/ancestor::tei:text/@n), "_")}##{data($p/ancestor::tei:div[1]/@xml:id)}##{data($p/ancestor::tei:div[2]/@xml:id)}##{data($p/ancestor::tei:div[3]/@xml:id)}##{$p/ancestor::tei:div[4]/tei:head/text()}##{data($p/ancestor::tei:div[5]/@xml:id)}</span>
                        else if (exists($p/ancestor::tei:div[4])) then
                            <span>{$p/text()}##{substring-after(data($p/ancestor::tei:text/@n), "_")}####{data($p/ancestor::tei:div[1]/@xml:id)}##{data($p/ancestor::tei:div[2]/@xml:id)}##{$p/ancestor::tei:div[3]/tei:head/text()}##{data($p/ancestor::tei:div[4]/@xml:id)}</span>  
                        else
                            <span>{$p/text()}##{substring-after(data($p/ancestor::tei:text/@n), "_")}######{data($p/ancestor::tei:div[1]/@xml:id)}##{$p/ancestor::tei:div[2]/tei:head/text()}##{data($p/ancestor::tei:div[3]/@xml:id)}</span>    
                    return
                        $pp
                    }
            </div>
return
    xmldb:store($config:data-root||"/output", app:addzero(xs:string($i),3)||".xml",$table)
};
declare function app:addzero($number as xs:string, $digit as xs:integer) as xs:string{
let $result:=
    if (string-length(($number)) lt $digit) then
        app:addzero("0"||$number, $digit)
    else
        xs:string($number)
return
$result
};
declare function app:left-column($node as node(), $model as map(*), $tei as xs:string?, $query as xs:string?,$coll as xs:string?) {
      (:判定有無資料庫指定coll以進入檢索或瀏覽模式:)
   if ($tei) then
        app:tei()
   else if ($query) then 
        app:search()
   else if ($coll) then
        app:browse()
   else
      app:homepage()
};
declare function app:search(){
let $query := request:get-parameter("query", ())
let $coll := request:get-parameter("coll", ())
let $volume := request:get-parameter("volume", ())
let $author := request:get-parameter("author", ())
let $filtered-q := replace($query, "[&amp;&quot;-*;-`~!@#$%^*()_+-=\[\]\{\}\|';:/.,?(:]", "")
let $data :=
    if ($coll) then
        if ($volume) then
            doc($config:data-root||"/"||$coll||"/"||$volume||".xml")/tei:TEI
        else if ($author) then
            if ($coll eq "main") then
                collection($config:data-root||"/main")/tei:TEI[matches (./tei:teiHeader/tei:fileDesc/tei:titleStmt/author, $author)]
            else 
                collection($config:data-root||"/"||$coll)//tei:TEI[matches (./tei:text/tei:body/tei:div/tei:div, $author)](:之後考慮做成另外的檔案以節省檢索時間:)
        else
            collection($config:data-root||"/"||$coll)/tei:TEI
    else 
        collection($config:data-root)//tei:TEI
let $result :=
    if ($query eq "0") then 
        <div>
            <h2>請在右欄的檢索窗格輸入檢索詞進行檢索。</h2>
        </div>
    else
        let $hits := $data/tei:text/tei:body/tei:div/tei:div/tei:div[matches(., $query)]
        let $hits1 := $hits/tei:head[matches(., $query)]
            let $hits11 := 
                for $p in $hits1
                order by base-uri($p)
                return
                    $p
        let $hits2 := $hits//tei:p[matches(., $query)]
            let $hits22 := 
            for $p in $hits2
            order by base-uri($p)
            return
                $p
        let $hits3 := $hits//tei:l[matches(., $query)]
            let $hits33 := 
            for $p in $hits3
            order by base-uri($p)
            return
                $p
        let $hits4 := $hits/*[name()!="head"]//tei:hi[matches(., $query)]
            let $hits44 := 
            for $p in $hits4
            order by base-uri($p)
            return
                $p
        return 
            <div>
                <h2>檢索「<match>{$query}</match>」的結果：</h2>
                <p><a href="#title">共有<match>{count($hits1)}</match>首篇/詩題含有檢索詞</a>；<a href="#para">共有<match>{count($hits2)}</match>段段落含有檢索詞</a><br/>
                <a href="#pline">共有<match>{count($hits3)}</match>行詩句含有檢索詞</a>；<a href="#anno">共有<match>{count($hits4)}</match>個註解含有檢索詞</a></p>
                <a name="title"><h3>篇題：</h3></a>
                <div class="column2">
                <ul>
               {for $hit at $count in $hits11
                let $result1:= app:makelink($hit, $query, $count)
                return
                <li>{$result1}</li>}
                </ul>
                </div>
                <a name="para"><h3>段落：</h3></a>
                <ul>
                {for $hit at $count in $hits22
               let $result1:= app:makelink($hit, $query, $count)
                return
                <li>{$result1}</li>}
                </ul>
                <a name="pline"><h3>詩句：</h3></a>
                <ul>
                {for $hit at $count in $hits33
                let $result1:= app:makelink($hit, $query, $count)
                return
                <li>{$result1}</li>}
                </ul>
                <a name="anno"><h3>註解：</h3></a>
                <ul>
                {for $hit at $count in $hits44
                let $result1:= app:makelink($hit, $query, $count)
                return
                <li>{$result1}</li>}
                </ul>
            </div>
return
    $result
};
declare function app:makelink($node as node(), $query as xs:string, $count as xs:integer){
    let $coll := request:get-parameter("coll", ())
    let $hitf := functx:get-matches-and-non-matches($node, $query)
    let $hitlink := base-uri($node)
    let $title := doc($hitlink)/tei:TEI/tei:teiHeader/tei:fileDesc/tei:titleStmt/tei:title/text()
    let $coll:=
        if (matches (data(doc($hitlink)/tei:TEI/tei:text/@n), "_")) then
            substring-before(data(doc($hitlink)/tei:TEI/tei:text/@n), "_")
        else
            data(doc($hitlink)/tei:TEI/tei:text/@n)
    let $juan :=  $node/ancestor::tei:div[matches(data(./@xml:id), $coll||"j_")][1]/@xml:id
    let $item := $node/ancestor::tei:div[matches(data(./@xml:id), $coll||"i_")][1]/@xml:id
    let $volume := substring-before(substring-after(substring($hitlink, 19), "/"), ".")
    let $urilink := "index.html?coll="||$coll||"&amp;volume="||$volume||"&amp;juan="||data($juan)||"&amp;item="||data($item)
    return
    <span>{$count}. <a>{attribute href {$urilink}}{$title}第{substring-after(data($juan), "_")}卷/{$item/../../tei:head}/〈{$item/../tei:head}〉<hi>{data($item)}</hi></a><br/> {$hitf}
    </span>
};
declare function app:topictext($node as node(), $text as node()) as node(){
let $text:=
    if (exists($node/../tei:head)) then
        let $nodenext:=$node/..
        let $textnext:=
            <div>{$nodenext/tei:head}/{$text}</div>
        return
            app:topictext($nodenext, $textnext)
    else $text
return
    $text
};
declare function app:tei() as node()?{
    let $tei := request:get-parameter("tei", ())
    let $ana :=request:get-parameter("ana", ())
    let $order :=request:get-parameter("order", ())
    let $data:= 
        if (number($tei) < 20) then collection($config:data-root||"/qss")
        else doc($config:data-root||"/main/mbs.xml")
    let $coll:=
        if (number($tei) < 20) then "qss"
        else "main"
    let $volume:=
        if (number($tei) < 20) then "" else "mbs"
    let $catl := $data//tei:p/@ana
    let $catl2 :=
        for $single in $catl
        return
            tokenize(data($single), "\s+")
    let $catl-d := distinct-values(data($catl2))
    let $shaoyong:=$data//tei:body/tei:div/tei:div[matches(./tei:head, "邵雍")]
    let $mbstext:=doc($config:data-root||"/main/mbstaxonomy.xml")
    let $result:=
         if ($tei eq "0") then
                <div>
                    <h2>TEI示範</h2>
                    <p>請依照右欄的指示，進行TEI能做什麼的功能示範。</p>
                </div>
        else if ($tei eq "21") then
            <div>
                <h2>《明本釋》標註分類表</h2>
                <table border="1" width="50%">
                    <tr>
                        <th>類一</th>
                        <th>類二</th>
                        <th>類三</th>
                    </tr>
                     {
                    for $p1 in $mbstext/tei:taxonomy/tei:category
                        for $p2 in $p1/tei:category
                            for $p3 in $p2/tei:category
                    return
                    <tr><td>{data($p1/@xml:id)}</td><td>{data($p2/@xml:id)}</td><td>{data($p3/@xml:id)}</td></tr>}
                       {
                    let $p1 :=
                        for $p2 in $mbstext/tei:taxonomy/tei:category/tei:category
                        return
                        if ($p2/tei:category) then ()
                        else $p2
                   for $p3 in $p1
                    return
                    <tr><td>{data($p3/../@xml:id)}</td><td>{data($p3/@xml:id)}</td><td></td></tr>}
                </table>
            </div>
        else if ($tei eq "20") then
            if (string-length($ana)>0) then 
                <div>
                <h2>含有{$ana}分類的共有<hi>{count($data//tei:p[matches(data(./@ana), $ana)])}</hi>段<br/>每個段落都列在節標題後：</h2>
                <ul>
                {for $p at $count in $data//tei:p[matches(data(./@ana), $ana)]
                let $pp:=functx:remove-elements($p, "hi")
                return
                    <li>{$count}. {$p/../tei:head}<hi>{substring-after(data($p/../@xml:id), "_")}</hi><br/>{$p}</li>
                }
                </ul>
                <p><a href="index.html?tei=20">按這裡回到上一頁分類表</a></p>
                </div>
            else
                <div>
                    <h2>《明本釋》正文裏出現的分類及次數<br/>也可以點擊條目，查看各分類詞出現的正文段落</h2>
                    <table border="1" width="50%">
                        <tr>
                            <th>編號</th>
                            <th>分類</th>
                            <th>次數</th>
                        </tr>
                         {
                        for $p at $count in $catl-d
                        order by $p
                        return
                        <tr><td>{$count}</td><td>
                            {let $link:="index.html?tei=20&amp;ana="||substring-after($p,"_")
                            return
                            <a>{attribute href {$link}}{substring-after($p,"_")}</a>
                            }
                            </td><td>{count($catl[matches(data(.), $p)])}</td></tr>}
                    </table>
                </div>
         else if ($tei eq "1") then
                <div>
                <h2>{$tei}、《全宋詩》中，總共收有邵雍詩<font color="red"> {count($shaoyong//tei:lg)} </font>首。共有<font color="red"> {count($shaoyong/tei:div)} </font>首詩題<br/>過濾碼：$data//tei:body/tei:div/tei:div[matches(./tei:head, "邵雍")]<br/>先給予每一首詩的詩題識別碼，之後也可以方便做篩選。<br/>　　先將每首詩的識別碼、詩題、首數、所在卷別以及年分輸出。再利用MSExcel來統整與計算資料，可以看出邵雍詩作的年分分布。</h2>
                <p>從《全宋詩》中過濾出邵雍的詩。但《全宋詩》求全不求精，所以末卷最後幾首輯佚詩，並不可靠。</p>
                <table border="1">
                    <tr>
                        <th>識別碼</th>
                        <th>詩題</th>
                        <th>首數</th>
                        <th>卷別</th>
                        <th>年分</th>
                    </tr>
                    {
                    for $p at $count in $shaoyong/tei:div
                    order by number(substring-after(data($p/@xml:id), "_"))
                    return
                    <tr><td>{substring-after(data($p/@xml:id), "_")}</td><td>{$p/tei:head//tei:c}</td><td>{count($p//tei:lg)}</td><td>{substring-after(data($p/../../@xml:id),"_")}</td><td>{data($p/tei:head/tei:date[1]/@when)}</td></tr>}
                </table>
            </div>
else if ($tei eq "2") then
    let $total:=count($shaoyong//tei:div/tei:lg)
    let $total2:=count($shaoyong//tei:div[exists(./tei:div)])
    return
        <div>
            <h2>{$tei}、《全宋詩》中，共收有邵雍<hi>{$total2}</hi>首組詩。<br/>
        組詩中的詩共<hi>{$total}</hi>首。
        </h2>
        <p>邵雍的〈首尾吟〉為形式明顯類似的組詩，所以要了解〈首尾吟〉有必要了解邵雍組詩的一般情況。</p>
        <table border="1">
                    <tr>
                        <th>識別碼</th>
                        <th>詩題</th>
                        <th>首數</th>
                        <th>卷別</th>
                        <th>年分</th>
                    </tr>
                    {
                    for $p at $count in $shaoyong//tei:div[exists(./tei:div)]/tei:head
                    order by number(data($p/../../../@xml:id))
                    return
                        <tr><td>{substring-after(data($p/../@xml:id), "_")}</td><td>{$p/tei:c}</td><td>{count($p/..//tei:div)}</td><td>{substring-after(data($p/../../../@xml:id), "_")}</td><td>{data($p/tei:date[1]/@when)}</td></tr>}
            </table>
        </div>
else if ($tei eq "3") then
    let $total:=count($shaoyong//tei:div/tei:head[contains(data(.),"觀物")])
    let $total2:=count($shaoyong//tei:div/tei:head[contains(data(.),"觀物")]/..//tei:lg)
    return
        <div>
            <h2>{$tei}、邵雍詩詩題中有「觀物」一詞的詩題共<font color="red">{$total}</font>首，共有詩<font color="red">{$total2}</font>首。</h2>
            <p>「觀物」為邵雍重要思想概念，邵雍在詩裏表現的內容，可以說是邵雍觀物的實踐，而以「觀物」為題的詩，更應能具體彰顯邵雍思想、生活與其詩作之間的關係。</p>
            <table border="1" width="500">
                        <tr>
                            <th>識別碼</th>
                            <th>詩題</th>
                            <th>首數</th>
                            <th>卷別</th>
                            <th>年分</th>
                        </tr>
                    {
                    for $p at $count in $shaoyong//tei:div/tei:head[contains(data(.),"觀物")]
                    return
                        <tr><td>{substring-after(data($p/../@xml:id),"_")}</td><td>{$p}</td><td>{count($p/..//tei:lg)}</td><td>{$p/ancestor::tei:div[matches(data(./@xml:id), "_")]/tei:head}</td><td>{data($p/tei:date[1]/@when)}</td>
                        </tr>}
            </table>
            {            for $p in $shaoyong//tei:div[matches(data(./tei:head),"觀物")]
            order by number(substring-after($p/@xml:id, "_"))
            return
                <div>
                <h2>{$p/tei:head}　<hi>{substring-after($p/@xml:id, "_")}</hi></h2>
                <ol>{
                        for $pp in $p//tei:lg
                        return
                            <oi>{$pp}<br/></oi>
                    }
                </ol>        
                </div>   
                }
        </div>
else if ($tei eq "4") then
    let $char:=distinct-values($shaoyong//tei:div//tei:lg/tei:l/tei:c)
    let $total:=count($char)
    let $total2:=count($shaoyong//tei:div//tei:lg/tei:l/tei:c)
    return
        <div>
        <h2>邵雍詩共包含<font color="red">{$total}</font>個不同的字，總共有<font color="red">{$total2}</font>字。<br/></h2>
        <p>詩中用字的詩況，可以幫我們確定作者用字習慣、乃至於整個創作風格的改變。</p>
        {for $p in $shaoyong/tei:div
                    for $c in $p//tei:lg/tei:l/tei:c
                    return
                    <span>{$c},{data($p/tei:head/tei:date[1]/@when)}<br/></span>}
        </div>
else if ($tei eq "5") then
    let $p:=$shaoyong/tei:div/tei:head[matches(data(.), "吟[\s\n<]")]
    return
            <div>
                <h2>{$tei}、邵雍詩有<font color="red"> {count($shaoyong/tei:div)} </font>首詩題，共有<font color="red"> {count($shaoyong//tei:lg)} </font>首詩。<br/>以「吟」做為結束的，共有<font color="red"> {count($p)} </font>首詩題，<font color="red"> {count($p/..//tei:lg)} </font>首詩作。</h2>
                <table border="1">
                    <tr>
                        <th>識別碼</th>
                        <th>詩題</th>
                        <th>首數</th>
                        <th>卷別</th>
                        <th>年分</th>
                    </tr>
                    {
                    for $pa at $count in $p
                    order by number(substring-after($pa/../@xml:id, "_"))
                    return
                    <tr><td>{substring-after(data($pa/../@xml:id),"_")}</td><td>{$pa}</td><td>{count($pa/..//tei:lg)}</td><td>{substring-after(data($pa/../../../@xml:id),"_")}</td><td>{data($pa/tei:date[1]/@when)}</td></tr>}
                </table>
            </div>
else if ($tei eq "6") then
    <h2>可以如同字頻的方式進行。</h2>
else if ($tei eq "7") then
    <div class="row-fluid">
        <div class="span6">
            <ol>{
            let $shouweiyin:=$shaoyong/tei:div[matches(data(./tei:head), "首尾吟")]
            for $pa at $count in $shouweiyin/tei:div
            order by $pa/@xml:id
            return
            <li>{$pa/tei:lg/tei:l[2]/*[name(.)!="pc"]}　{substring-after(data($pa/@xml:id),"_")}　　{data($pa//tei:date[1]/@when)}</li>   
            }
            </ol>
            </div>
            <div class="span6">
                    <ol>{
                let $shouweiyin:=$shaoyong/tei:div[matches(data(./tei:head), "首尾吟")]
                for $pa at $count in $shouweiyin/tei:div//tei:l[2]
                order by $pa
                return
                <li>{$pa/*[name(.)!="pc"]}　{substring-after(data($pa/../../@xml:id),"_")}　{data($pa/../..//tei:date/@when)}</li>   
                }{
                let $shouweiyin:=$shaoyong/tei:div[matches(data(./tei:head), "首尾吟")]
                let $pb:=$shouweiyin/tei:lg
                return
                    <li>{$pb/tei:l[2]/*[name(.)!="pc"]}　{substring-after(data($pb/../@xml:id),"_")}　{data($pb/../tei:head/tei:date[1]/@when)}</li>
                }
                </ol>
            </div>
      </div>
else if ($tei eq "8") then
    <div class="row-fluid">
        <div class="span6">
                <ol>{
                let $shouweiyin:=$shaoyong/tei:div[matches(data(./tei:head), "首尾吟")]
                for $pa at $count in $shouweiyin/tei:div/tei:lg
                order by $pa/tei:l[2]
                return
                <li>{$pa/tei:l[7]/*[name(.)!="pc"]}　　{substring-after(data($pa/../@xml:id),"_")}</li>   
                }{
                let $shouweiyin:=$shaoyong/tei:div[matches(data(./tei:head), "首尾吟")]
                let $pb:=$shouweiyin/tei:lg
                return
                    <li>{$pb/tei:l[7]/*[name(.)!="pc"]}　　{substring-after(data($pb/../@xml:id),"_")}</li>
                }
                </ol>
            </div>
            <div class="span6">
                    <ol>{
                let $shouweiyin:=$shaoyong/tei:div[matches(data(./tei:head), "首尾吟")]
                for $pa at $count in $shouweiyin/tei:div//tei:l[2]
                order by $pa
                return
                <li>{$pa/*[name(.)!="pc"]}　　{substring-after(data($pa/../../@xml:id),"_")}</li>   
                }{
                let $shouweiyin:=$shaoyong/tei:div[matches(data(./tei:head), "首尾吟")]
                let $pb:=$shouweiyin/tei:lg
                return
                    <li>{$pb/tei:l[2]/*[name(.)!="pc"]}　　{substring-after(data($pb/../@xml:id),"_")}</li>
                }
                </ol>
            </div>
      </div>
else if ($tei eq "9") then
    <div class="row-fluid">
       <div class="span6">
            {
            let $p:=$shaoyong/tei:div/tei:head
            return
                   <ol>{
                        for $p-p at $count in $p/tei:persName
                        order by $p/@xml:id
                        return
                        <li>{$p-p}</li>   
                        }
                    </ol>
                }
       </div>
       {<div class="span6">
                <ol>{
                let $p:=$shaoyong/tei:div/tei:head
                for $p-pl in $p/tei:placeName
                return
                    <li>{$p-pl}</li>
                }
                </ol>
        </div>}
      </div>
else if ($tei eq "10") then
    <div class="row-fluid">
       <div class="span6">
            {let $p:=$shaoyong/tei:div/tei:head
            return
                <table border="1">
                    <tr>
                        <th>識別碼</th>
                        <th>年分</th>
                        <th>名字結構</th>
                        <th>姓</th>
                        <th>字</th>
                    </tr>
                {
                for $p-p at $count in $p/tei:persName
                let $p-node := 
                    for $s in $p-p/*
                    return
                        concat(local-name($s), $s/@type)
                order by $p/@xml:id
                return
                <tr>
                    <td>{substring-after(data($p-p/../../@xml:id),"_")}</td>
                    <td>{data($p-p/../tei:date[1]/@when)}</td>
                    <td>{$p-node}</td>
                    <td>{$p-p/tei:surname}</td>
                    <td>{$p-p/tei:addName[@type="字"]}</td>
                </tr>
                }
                </table>}
        </div>
        <div class="span6">
        {
        let $p:=$shaoyong/tei:div/tei:head
        return
            <table border="1">
                <tr>
                    <th>識別碼</th>
                    <th>年分</th>
                    <th>地名結構</th>
                    <th>地名</th>
                </tr>
            {
            for $p-p at $count in $p/tei:placeName
            let $p-node := 
                for $s in $p-p/*[name(.)!="c"]
                return
                    concat(local-name($s), $s/@type)
                    order by $p/@xml:id
                    return
                        <tr>
                            <td>{substring-after(data($p-p/../../@xml:id),"_")}</td>
                            <td>{data($p-p/../tei:date[1]/@when)}</td>
                            <td>{$p-node}</td>
                            <td>{data($p-p)}</td>
                        </tr>
            }
            </table>}
        </div>
    </div>
else if ($tei eq "11") then
    let $pp:=$shaoyong/tei:div[exists(.//tei:lg/tei:lg)]
    return
        <table border="1">
                    <tr>
                        <th>識別碼</th>
                        <th>詩題</th>
                        <th>卷別</th>
                        <th>年分</th>
                        <th>摘句</th>           
                    </tr>
                    {
                    for $p at $count in $pp
                    order by data($p/@xml:id)
                    return
                        <tr><td>{substring-after(data($p/@xml:id),"_")}</td><td>{$p/tei:head/*[name(.)!="hi"]}</td><td>{substring-after(data($p/../../@xml:id), "_")}</td><td>{data($p/tei:head/tei:date[1]/@when)}</td><td>{functx:remove-elements-deep($p, "hi")//tei:lg/tei:lg}</td></tr>
                    }
            </table>
    else ()
    return
                $result
};
declare function app:from-session($node as node(), $model as map(*)) {
    let $cxd := session:get-attribute("apps.cxd")
    return
            map { "cxd" := $cxd }
};
declare function app:work-title($work as element(tei:TEI)) {
    $work/tei:teiHeader/tei:fileDesc/tei:titleStmt/tei:title/text()
};

declare function app:browse() as node() {
let $coll := request:get-parameter("coll", ())
let $volume1 := request:get-parameter("volume", ())
let $volume:=
    if (matches($volume1, "_")) then
        substring-after($volume1, "_")
    else
        $volume1
let $author := request:get-parameter("author", ())
let $juan := request:get-parameter("juan", ())
let $item := request:get-parameter("item", ())
let $list:=doc($config:data-root||"/"||"list.xml")
let $collection-title :=
   $list/tei:TEI/tei:text/tei:body/tei:listBibl/tei:bibl/tei:title/text()[matches(data(../@xml:id), $coll)]
let $data := collection($config:data-root||"/"||$coll)
let $volume-title :=
   doc($config:data-root||"/"||$coll||"/"||$volume||".xml")/tei:TEI/tei:teiHeader/tei:fileDesc/tei:titleStmt/tei:title/text()
let $result := 
    (:冊數瀏覽:)
    if ($volume) then
        (:如果沒有指定冊數:)
       if ($volume eq "0")  then
            <div>
                    <h2>冊數瀏覽</h2>
                    <p>請於下面列表點選{$collection-title}中的書冊進行瀏覽：</p>
                    <div  class="column3">
                    <ol>
                {
                    for $vol in $data//tei:text
                    order by data($vol/@n)
                    return                        
                         <li>
                         {let $link:="index.html?coll="||$coll||"&amp;volume="||data($vol/@n)
                          return
                            <a> {attribute href {$link}}{$vol/../tei:teiHeader/tei:fileDesc/tei:titleStmt/tei:title/text()}</a>
                          }
                         </li>
                     }
                        </ol></div>
               </div>
        else 
        (:volume exists but not "0":)
            if ($juan) then
                if ($item) then
                   let $header := 
                            <h2>你正在瀏覽{$volume-title}第{substring-after($juan, "_")}卷的篇章</h2>
                   let $dataitem := doc($config:data-root||"/"||$coll||"/"||$volume||".xml")/tei:TEI/tei:text/tei:body/tei:div[data(./@xml:id) eq $juan]/tei:div/tei:div[data(./@xml:id) eq $item]
                    return
                        <div>
                            {$header}
                            <h2>{$dataitem/tei:head}　<hi>{substring-after(data($dataitem/@xml:id), "_")}</hi></h2>
                            {functx:change-element-names-deep(functx:remove-elements($dataitem, "head"), xs:QName("tei:title"), xs:QName("b"))}
                        </div>
                else (: $juan introduction:)
                   let $header := 
                            <h2>你正在瀏覽{$volume-title}第{substring-after($juan, "_")}卷的篇章，請點選下面連結以進行卷中篇章瀏覽。</h2>
                   let $datavolume := doc($config:data-root||"/"||$coll||"/"||$volume||".xml")
                   return
                        <div>
                            {$header}
                            <div class="column2">
                            <ol>
                                {
                                for $p in $datavolume//tei:div[data(./@xml:id) eq $juan]/tei:div/tei:div
                                return
                                    <li>
                                    {
                                    let $link := "index.html?coll="||$coll||"&amp;volume="||$volume||"&amp;juan="||$juan||"&amp;item="||data($p/@xml:id)
                                     return
                                    <a>{attribute href {$link}}{$p/tei:head}  <hi>{substring-after(data($p/@xml:id),"_")}</hi></a>
                                    }
                                    </li>
                                }
                            </ol>
                            </div>
                        </div>
            else (:volume exists, not 0 and juan does not exist. get the volume, hyperlink its juan:)
               let $header := 
                        <h2>你正在瀏覽{$volume-title}，<br/>本冊包括下列卷數：</h2>
               let $datavolume := doc($config:data-root||"/"||$coll||"/"||$volume||".xml")
               return
                    <div>
                        {$header}
                        <div class="column2">
                        <ol>
                         { for $p in $datavolume/tei:TEI/tei:text/tei:body/tei:div
                            return
                                <li>{let $link:="index.html?coll="||$coll||"&amp;volume="||$volume||"&amp;juan="||data($p/@xml:id)
                                 return
                                <a> {attribute href {$link}} {data($p/tei:head)} </a>
                                }</li>}
                            </ol>
                        </div>
                    </div>
      else if ($author) then  (:作者瀏覽:)
        if ($author eq "0") then
           let $author-names:=doc($config:data-root||"/main/list.xml")/tei:TEI/tei:teiHeader/tei:fileDesc/tei:titleStmt/tei:author[data(../tei:title/@type) eq "sub"]
           let $data:=collection($config:data-root||"/"||$coll)
           let $header := 
                    <h2>你正在瀏覽{$collection-title}，<br/>目前收錄資料包括下列作者：</h2>
           return
                <div>
                    {$header}
                    <div class="column3">
                    <ol>
                        {
                        let $author-list:=
                            if ($coll eq "main") then
                                $author-names
                            else 
                                $data//tei:TEI/tei:text/tei:body/tei:div/tei:div/tei:head/text()
                        for $p in distinct-values($author-list)
                        order by $p
                        return
                            <li>
                            {
                            let $link:="index.html?coll="||$coll||"&amp;author="||data($p)
                             return
                            <a> {attribute href {$link}} {$p}</a>
                            }
                            </li>
                        }
                    </ol>
                    </div>
                </div>
        else
            if ($juan) then (:if $juan exists:)
                if ($item) then (:if $item exists:)
                    let $dataitem := collection($config:data-root||"/"||$coll||"/"||$volume)//tei:div[matches(data(./@xml:id), $juan)]/tei:div/tei:div[matches(data(./@xml:id), $item)]
                    let $volume-title :=
   $dataitem/ancestor::tei:TEI/tei:teiHeader/tei:fileDesc/tei:titleStmt/tei:title/text()
                   let $header := 
                            <h2>你正在瀏覽{$volume-title}{$author}的著作：第{substring-after($juan, "_")}卷</h2>
                    return
                        <div>
                            {$header}
                            <h2>{$dataitem/tei:head} <hi>{substring-after(data($dataitem/@xml:id),"_")}</hi></h2>
                            {functx:remove-elements($dataitem, "head")}
                        </div>
                else (: $item introduction:)
                    let $datajuan := collection($config:data-root||"/"||$coll)//tei:TEI/tei:text/tei:body/tei:div[data(./@xml:id)=$juan]/tei:div[matches(./tei:head/text(), $author)]
                    let $volume-title :=
   $datajuan/ancestor::tei:TEI/tei:teiHeader/tei:fileDesc/tei:titleStmt/tei:title/text()
                    let $header := 
                        <h2>你正在瀏覽{$author}的著作：{$volume-title}第{substring-after($juan, "_")}卷，本卷包括下列各篇：</h2>
                    return
                        <div>
                            {$header}
                            <div class="column2">
                            <ul>
                                { for $p at $count in $datajuan/tei:div
                                return
                                    <li>
                                    {let $link := "index.html?coll="||$coll||"&amp;author="||$author||"&amp;juan="||$juan||"&amp;item="||data($p/@xml:id)
                                     return
                                    <span>{$count}<a> {attribute href {$link}} {$p/tei:head}  <hi>{substring-after(data($p/@xml:id), "_")}</hi></a></span>}
                                    </li>
                                }
                            </ul>
                            </div>
                        </div>
            else (:author exists, not 0 and juan does not exist. get the volume, hyperlink its juan:)
                let $dataauthor :=
                    if ($coll eq "main") then 
                    collection($config:data-root||"/main")//tei:TEI/tei:text/tei:body/tei.div[matches(/tei:TEI/tei:teiHeader/tei:fileDesc/tei:titleStmt/tei:author/text(), $author)]
                    else  collection($config:data-root||"/"||$coll||"/"||$volume)//tei:TEI/tei:text/tei:body/tei:div[matches(./tei:div/tei:head/text(), $author)]
                let $header := 
                        <h2>你正在瀏覽{$collection-title}中{$author}的著作，<br/>共有{count($dataauthor)}卷：</h2>
                return
                   <div>
                            {$header}
                            <div class="column3">
                            <ul>
                                {
                                let $data2 :=
                                    for $p in $dataauthor
                                    order by data($p/@xml:id)
                                    return
                                        $p
                                  for $pp at $count in $data2                                  
                                  return
                                    <li>
                                    {
                                    let $link := "index.html?coll="||$coll||"&amp;author="||$author||"&amp;juan="||data($pp/@xml:id)
                                     return
                                    <span>{$count}.<a>{attribute href {$link}} {$pp/tei:head} </a></span>
                                    }
                                    </li>
                                }
                            </ul>
                            </div>
                        </div>
      else
            <div class="span8" id="content">
                <h1>瀏覽模式</h1>
                <div class="alert alert-success">
                    <p>請點選：<br/>
                    <ul>
                    <li><a>{attribute href {"index.html?coll="||$coll||"&amp;volume=0"}}冊數瀏覽模式</a></li>
                    <li><a>{attribute href {"index.html?coll="||$coll||"&amp;author=0"}}作者瀏覽模式</a></li>
                    </ul></p>                
                </div>
            </div>
    return
    <div>
        {$result}
    </div>
};
declare  function app:right-column($node as node(), $model as map(*)) {
let $coll := request:get-parameter("coll", ())
let $volume1 := request:get-parameter("volume", ())
let $tei := request:get-parameter("tei", ())
let $volume:=
    if (matches($volume1, "_")) then
        substring-after($volume1, "_")
    else
        if (number($tei)>12) then "mbs"
        else $volume1
let $author := request:get-parameter("author", ())
let $list:=doc($config:data-root||"/list.xml")
let $juan := request:get-parameter("juan", ())
let $item := request:get-parameter("item", ())
let $tei := request:get-parameter("tei", "")
let $query := request:get-parameter("query", ())
let $collection-title :=
    if ($coll) then
$list/tei:TEI/tei:text/tei:body/tei:listBibl/tei:bibl/tei:title/text()[matches(data(../@xml:id), $coll)]
    else ()
let $volume-title :=
   doc($config:data-root||"/"||$coll||"/"||$volume||".xml")/tei:TEI/tei:teiHeader/tei:fileDesc/tei:titleStmt/tei:title/text()
let $formlink := 
    if ($tei) then
        if (number($tei)>12) then
            "main"
        else
            "qss" 
    else $coll
let $form :=
           <form method="get" action="index.html">
                <label for="name">請輸入檢索詞：</label>
                <input name="query"/>
                <input type="hidden" name="coll"/> {attribute value {$formlink}}
                <input type="hidden" name="volume"/> {attribute value {$volume}}
                <input type="hidden" name="author"/> {attribute value {$author}}
                <input type="submit" value="進行檢索"/>
            </form>
let $column :=
    if ($tei) then
            <div>
            <h2>TEI能做什麼？</h2>
            <p>請點選下面示範選項，然後點擊「開始示範」鍵，以進行示範。<br/>或利用上述輸入框格，進行全宋詩全文檢索。</p>
            <form>
                <input type="radio" name="tei" value="21"/>　21.《明本釋》標註分類表<br/>
                <input type="radio" name="tei" value="20"/>　20.《明本釋》正文裏出現的分類及次數<br/>
                <input type="radio" name="tei" value="1"/>　1.《全宋詩》中有幾首邵雍的詩？<br/>
                <input type="radio" name="tei" value="2"/>　2.邵雍留存有幾首組詩？<br/>
                <input type="radio" name="tei" value="3"/>　3.詩題中有「觀物」一詞的詩有幾首？<br/>
                <input type="radio" name="tei" value="4"/>　4.邵雍詩用字字頻的情況如何？<br/>
                <input type="radio" name="tei" value="5"/>　5.詩題以「吟」字結束的有幾首？<br/>
                <input type="radio" name="tei" value="6"/>　6.（詞頻與其年分分布？）<br/>
                <input type="radio" name="tei" value="7"/>　7.〈首尾吟〉中的第二句列表<br/>
                <input type="radio" name="tei" value="8"/>　8.〈首尾吟〉中的第七句列表<br/>
                <input type="radio" name="tei" value="9"/>　9.詩題中的人名與地名<br/>
                <input type="radio" name="tei" value="10"/>　10.人名與地名的年分分布為何？<br/>
                <input type="radio" name="tei" value="11"/>　11.邵雍1070-1077的政治詩<br/>
                <br/>
                <input type="hidden" name="coll" value="qss"/>
                <input type="submit" value="開始示範"/>
            </form>
            </div>
    else if ($coll) then 
               if ($volume) then
                    if ($volume eq "0") then
                            let $data := collection($config:data-root||"/"||$coll)
                            return
                                <div>
                                        <h2>冊數瀏覽</h2>
                                        <p>請在左欄點選{$collection-title}冊數進行瀏覽：</p>                                        
                                 </div>                       
                     else (:volume exists but not "0":)
                         if ($juan) then
                             if ($item) then
                                let $header :=
                                         <h3>你可以點選下列連結，瀏覽本卷其它篇章</h3>
                                 let $data := doc($config:data-root||"/"||$coll||"/"||$volume||".xml")/tei:TEI/tei:text/tei:body/tei:div[data(./@xml:id) eq $juan]
                                 return
                                        <div>
                                            {$header}
                                            <ol>
                                                {
                                                for $p in $data/tei:div/tei:div
                                                return
                                                    <li>
                                                    {
                                                    let $link := "index.html?coll="||$coll||"&amp;volume="||$volume||"&amp;juan="||$juan||"&amp;item="||data($p/@xml:id)
                                                     return
                                                    <a>{attribute href {$link}}{$p/tei:head}  <hi>{substring-after(data($p/@xml:id),"_")}</hi></a>
                                                    }
                                                    </li>
                                                }
                                            </ol>
                                        </div>
                            else (: $juan introduction:)
                                  let $header := 
                                          <h2>你正在瀏覽{$volume-title}，<br/>你可以點選下列連結，瀏覽其它卷的篇目</h2>
                                  let $data := doc($config:data-root||"/"||$coll||"/"||$volume||".xml")
                                    return
                                        <div>
                                            {$header}
                                            <ol>
                                             { for $p in $data/tei:TEI/tei:text/tei:body/tei:div
                                                return
                                                    <li>{let $link:="index.html?coll="||$coll||"&amp;volume="||$volume||"&amp;juan="||data($p/@xml:id)
                                                     return
                                                    <a> {attribute href {$link}} {data($p/tei:head)} </a>
                                                    }</li>}
                                                </ol>
                                        </div>
                    else (:volume exists, not 0 and juan does not exist. get the volume, hyperlink its juan:)
                        let $header := 
                                <h2>你正在瀏覽{$volume-title}，<br/>本冊包括左欄卷數；你也可以點選下列連結瀏覽其它冊：</h2>
                        let $data := collection($config:data-root||"/"||$coll)
                        let $pp :=
                            for $s in $data//tei:TEI
                            order by data($s//tei:text/@n)
                            return $s
                        return
                            <div>
                                {$header}
                                <ol>
                                 {for $p in $pp
                                    return
                                        <li>{
                                        let $link:="index.html?coll="||$coll||"&amp;volume="||data($p//tei:text/@n)
                                         return
                                        <a> {attribute href {$link}} {$p/tei:teiHeader/tei:fileDesc/tei:titleStmt/tei:title/text()} </a>
                                        }</li>}
                                    </ol>
                            </div>
              else if ($author) then 
                if ($author eq "0") then
                            let $header := 
                                    <h2>你正在瀏覽{$collection-title}，<br/>請點選左欄作者，進行瀏覽：</h2>
                            return
                                <div>
                                    {$header}
                                </div>
                else
                    if ($juan) then (:if $juan exists:)
                        if ($item) then (:if $item exists:)
                           let $header := 
                                    <h2>你可以點選下列連結，閱讀本卷{$author}其它的篇章：</h2>            
                           let $data := collection($config:data-root||"/"||$coll||"/"||$volume)/tei:TEI/tei:text/tei:body/tei:div[matches(data(./@xml:id), $juan)]/tei:div/tei:div
                            return
                                <div>
                                    {$header}
                                    <ol>{ for $p in $data
                                        return
                                            <li>
                                            {let $link := "index.html?coll="||$coll||"&amp;author="||$author||"&amp;juan="||$juan||"&amp;item="||($p/@xml:id)
                                             return
                                            <a> {attribute href {$link}} {$p/tei:head}  <hi>{substring-after(data($p/@xml:id), "_")}</hi></a>}
                                            </li>
                                        }</ol>
                                </div>
                        else (: $item introduction:)
                            let $data := collection($config:data-root||"/"||$coll)//tei:TEI/tei:text/tei:body/tei:div[matches(./tei:div/tei:head/text(), $author)]
                            let $header := 
                                    <h2>你可以點選下列連結，瀏覧{$author}其它卷的篇目(共{count($data)}卷）：</h2>
                            return
                                   <div>
                                            {$header}
                                            <ul>
                                                {
                                                let $data2 :=
                                                    for $p in $data
                                                    order by number(substring-after(data($p/@xml:id), "_"))
                                                    return
                                                        $p
                                                  for $pp at $count in $data2                                  
                                                  return
                                                    <li>
                                                    {
                                                    let $link := "index.html?coll="||$coll||"&amp;author="||$author||"&amp;juan="||data($pp/@xml:id)
                                                     return
                                                    <span>{$count}.<a>{attribute href {$link}} {$pp/tei:head} </a></span>
                                                    }
                                                    </li>
                                                }
                                            </ul>
                                        </div>
                    else 
                        <div><h2>請點選左欄的卷目進行瀏覽。</h2></div>
                else
                    <div>
                        <h2>請點選左欄選項進行操作。</h2>
                    </div>
        else if ($query) then
            if ($query eq "0") then
                <div>
                    <p>請在上方檢索窗格輸入檢索詞。</p>
                </div>
            else
                <div>
                <p>左欄為檢索「{$query}」的結果。<br/>
                如果想進一步看到檢索結果的篇章，請點選出處連結。</p>
                </div>
        else 
            <div>
            <h2>歡迎進入「中國XML資料庫」</h2>
            <p>目前進行中的計畫有：<br/>
                (1)全宋文中的宋人書信<br/>
                (2)《全宋詩》中的邵雍詩<br/>
                您可以從上面的表單選擇進入「目前計畫」，或在上面的檢索窗格以篇章為單位輸入正規表示式檢索本站所有資料。</p>
                </div>
return
    <div>
        {$form}
        {$column}
    </div>
};
declare  %templates:wrap function app:volume($node as node(), $model as map(*), $coll as xs:string?) {
  if (string-length($coll) eq 3) then 
    let $data:=collection($config:data-root||"/"||$coll)
    return
        <li>
            <span>冊數瀏覽</span>
            <ol>
        {
            for $vol in $data//tei:text
            order by number($vol/@n)
            return                        
             <li>
             {let $link:="http://140.114.113.168:8080/exist/apps/cxd/qsw.html?coll="||$coll||"&amp;volume="||data($vol/@n)
              return
                <a> {attribute href {$link}}第{data($vol/@n)}冊</a>
              }
             </li>
         }
            </ol>
         </li>
  else if ($coll eq "song") then
    let $data:=collection($config:data-root||"/song")
    return
        <li>
            <span>書籍瀏覽</span>
            <ol>
            {
            for $vol in $data//tei:text
            order by number($vol/@n)
            return                        
             <li>
             {let $link:="http://140.114.113.168:8080/exist/apps/cxd/qss.html?coll=s&amp;volume="||data($vol/@n)
              return
                <a> {attribute href {$link}}第{data($vol/@n)}冊</a>
              }
             </li>
             }
             </ol>
        </li>
    else()
};
declare function app:juan($node as node(), $model as map(*), $coll as xs:string?, $volume as xs:string?, $author as xs:string?) {
if ($volume) then
            let $doc:=doc($config:data-root||"/"||$coll||"/"||$volume||".xml")
            return
                  <li class="dir">
                    <span>相關卷數</span>
                     <ol>
                    {
                        for $juan in $doc//tei:div
                         order by data($juan/@xml:id)            
                        return                        
                            <li>
                            {
                            let $link:="index.html?coll="||$coll||"&amp;volume="||$volume||"&amp;juan="||data($juan/@xml.id)
                            return
                                <a> {attribute href {$link}}第{substring-after(data($juan/@xml:id), $coll||"j")}卷</a>}
                             </li>
                             }
                           </ol>
                   </li>
else if ($author) then 
    ()
else ()
};
declare function app:qss($node as node(), $model as map(*), $query as xs:string?, $coll as xs:string?, $volume as xs:string?, $juan as xs:string?, $auhor as xs:string?) {
(:先檢查有無檢索詞，以決定是瀏覽模式還是檢索模式:)
  if ($query) then 
    ()
(:瀏覽模式，將該冊結果製作一個session:)
    (:冊數瀏覽:)
  else if ($volume) then
    (:開啟SESSION，留住整卷結果:)
     ()
(:什麼參數都沒有，就設定首頁:)
   else
        <div>
            <h2>全宋詩瀏覽檢索系統</h2>
            <p>請依右欄指示進行操作。</p>
        </div>
};
declare function app:author($node as node(), $model as map(*), $author as xs:string?) {
  if ($author) then
    ()
  else
     ()
};
declare function app:homepage() as element()* {
let $list:=doc("/db/apps/cxd/data/list.xml")/tei:TEI/tei:text/tei:body/tei:listBibl/tei:bibl
return
     <div class="row-fluid">
     <h1>China XML Database</h1>
             <div class="alert alert-success">
            <p>下面列表是本站已收集資料，你可以點選進行瀏覽；你也可以隨時依照右邊欄位的指示，進行各項操作。</p>
        </div>
         <ol>
            {for $p in $list/tei:title[data(./@type) eq "sub"]
            order by data($p/tei:title/@xml:id)
            return
                <li><a>{attribute href {"index.html?coll="||data($p/@xml:id)}}{data($p)}</a></li>}
            <li><a href="index.html?tei=0">TEI能做什麼？</a></li>
        </ol>
        <p>聯絡人：<a href="mailto://ptchu@mx.nthu.edu.tw">祝平次</a></p>
       </div>
};
declare function app:tfgh($node as node(), $model as map(*)) {
      (:判定有無資料庫指定coll以進入檢索或瀏覽模式:)
let $q := request:get-parameter("q", ())
let $data:=doc($config:data-root||"/main/tfgh.xml")/tei:TEI/tei:text/tei:body/tei:div/tei:div
let $dataclass:=doc($config:data-root||"/main/tfghclass.xml")/tei:taxonomy
let $answer:=
    for $p in $data
    return
        count($p/tei:p)
let $howmany:=distinct-values($answer)    
let $result:=  
   if ($q="1") then
        <div>
        <h2>1、共有{count($data)}個人答題，共有{count($data/tei:p)}個答案。</h2>
        </div>
    else if ($q="2") then
        <div>
        {for $p in $howmany
        order by $p
        return
        <h2>2、答{$p}題共有{count($data[count(./tei:p)=$p])}個人。</h2>}
        </div>
    else if ($q="3") then
        <table border="1" width="50%">
            <tr>
                <th>3、時間</th>
                <th>事實</th>
                <th>內容</th>
            </tr>
            {for $p at $count in $dataclass/tei:category[data(./@xml:id) eq "內"]/tei:category
            return
            <tr>
                <td>{data($dataclass/tei:category[data(./@xml:id) eq "時"]/tei:category[$count]/@xml:id)}</td>
                <td>{data($dataclass/tei:category[data(./@xml:id) eq "事"]/tei:category[$count]/@xml:id)}</td>
                <td>{data($p/@xml:id)}({$p/tei:catDesc})</td>
            </tr>            
            }
        </table>
    else if ($q="4") then
        <table border="1" width="50%">
            <tr>
                <th>4、分類</th>
                <th>數量</th>
            </tr>
            {for $p in $dataclass/tei:category/tei:category
            return
            <tr>
                <td>{data($p/@xml:id)}</td>
                <td>{count($data/tei:p[matches (data(./@ana), data($p/@xml:id))])}</td>
            </tr>            
            }
        </table>
    else if ($q="5") then
        <table border="1">
            <tr>
                <th>5、分類組合</th>
                <th>數量</th>
            </tr>
            {for $p in distinct-values(data($data/tei:p/@ana))
            order by $p
            return
            <tr>
                <td>{replace(replace($p, "#", ""), " ", ",")}</td>
                <td>{count($data/tei:p/@ana[matches(data(.), $p)])}</td>
            </tr>            
            }
        </table>
    else if ($q="6") then
        <div>
        <h2>
            6、三個答案分類一樣的人，共有{count($data[count(distinct-values(data(./tei:p/@ana))) eq 1 and count(./tei:p) eq 3])}人。<br/>
            她們的答案是：
        </h2>
        <table border="1">
            <tr>
                <th>編號</th>
                <th>答案/問題</th>
            </tr>
        {for $p at $count in $data[count(distinct-values(data(./tei:p/@ana))) eq 1]
        return
        <tr>
            <td>{$count}</td>
            <td>{for $pp in $p/tei:p
            return
                <span>{$pp}</span>}</td>
        </tr>
        }
        </table>
        </div>
    else if ($q="7") then
        <table border="1" width="100%">
            <tr>
                <th>內容分類</th>
                <th>問題</th>
                <th>關鍵詞</th>
            </tr>
            {for $p at $count in $data/tei:p
            order by substring-after(data($p/@ana), "#") || data($p/tei:term)
            return
            <tr>
                <td>{substring-after(substring-after(substring-after(data($p/@ana), "#"), "#"), "#")}</td>
                <td>{data($p)}</td>
                <td>{$p/tei:term}</td>
            </tr>            
            }
        </table>        
    else if ($q="8") then
        <div>
        <h2>8、所有問題/答案</h2>
        <table border="1" width="100%">
            <tr>
                <th>內容分類</th>
                <th>問題</th>
                <th>關鍵詞</th>
            </tr>
            {for $p at $count in $data/tei:p
            order by substring-after(data($p/@ana), "#") || data($p/tei:term)
            return
            <tr>
                <td>{substring-after(substring-after(substring-after(data($p/@ana), "#"), "#"), "#")}</td>
                <td>{data($p)}</td>
                <td>{$p/tei:term}</td>
            </tr>            
            }
        </table>
        </div>
   else
      <span>請利用右欄執行設定的功能。謝謝。</span>
return
    $result
};
