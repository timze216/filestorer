# filestorer 一个暂储文件的简单R 包

目的：

把变量保存成文件，可以在有效期内取回。可以设定被清除时间

可以检查根据返回值的判断是否更新，返回值 1 代表文件内容与上次保存一致（基于md5判断）



用法：

1. 暂存文件 store

   ```R
   library(filestorer)
   test = 'hello world'
   status = store(file = test, token = 'jafkahfiucsjsjafofa')
   if (status == 0){
     message('file have been saved')
   }
   ```

   

2. 取回文件 getback

   ```R
   library(filestorer)
   test = getback('test', token = 'jafkahfiucsjsjafofa')
   test
   ```

   
