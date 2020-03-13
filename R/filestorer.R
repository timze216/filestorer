

# 文件保存在用户家目录下的 .filestore/
# 获取目录 basepath
home <- as.character(Sys.getenv()['HOME'])
basepath <- file.path(home,'.filestore')
recordsfile = file.path(basepath,'records.rds')
if(!dir.exists(basepath)){
  dir.create(basepath)
}

# 获取记录 records
if(!file.exists(recordsfile)){
  tmp <- as.data.frame(matrix(ncol = 5))
  tmp = tmp[-1,]
  colnames(tmp) <- c('md5','filename','save_time','rm_time','token')
  saveRDS(tmp,recordsfile)
}
records = readRDS(recordsfile)

#' @title store
#' @param keepdays, how long will the file be kept, default is 7 days
#' @param token, a token with length more than 6
#' @param update, logical, if update = F, the file wont be overwrited
store <- function(file, keepdays=7, token, update = T) {
  if (nchar(token) < 7){
    stop('Length of token must be longer than 10')
  }
  md5 = digest::digest(file)
  s = .check(file,md5,token)
  # 如果已经存在同样的文件（md5）则不再保存
  if(s$status == 1){
    message('A same file: ',s$f_name, ' have been saved on ',s$save_time,
            'You can access it with token: ',s$token)
    return(1) # exited
  }

  # 如果存在同样的文件名且token 一致
  # 但是内容发生了变化
  if(s$status == 2 & update){
    message(s$f_name, ' last saved time is ',s$save_time,
            ', it will be updated')
  }
  if(s$status == 2 & !update){
    message(s$f_name, ' last saved time is ',s$save_time,
            ', it will not be updated')
    return(2)
  }

  # 保存文件
  saveRDS(file,file.path(basepath,md5))

  # 更新记录
  save_time = as.Date(Sys.time())
  rm_time = save_time + keepdays
  f_name = as.character(substitute(file))
  new_rec = data.frame(md5,f_name,save_time,rm_time,token)
  colnames(new_rec) <- c('md5','filename','save_time','rm_time','token')
  records = rbind(records,new_rec)
  saveRDS(records,recordsfile)

  # 清理过期文件
  now <- as.Date(Sys.time())
  idx <- which(records$rm_time < now)
  sapply(idx, function(x){.clean(x)})
  return(0) # 0 成功，1 文件已经存在且更新 2 文件存在不更新
}


#' @title getback
#' @param filename, the file need to getback
#' @param token, a token as same as the one in store()
#' @return stored object
getback <- function(filename,token) {
  rec = readRDS(recordsfile)
  e = which(rec$token == token & rec$filename == file)
  if(length(e) > 0){
    md5 = md5 = rec$md5[e]
    rds = readRDS(file.path(basepath,md5))
    return(rds)
  } else {
    message('None file found, PLS check the file name or token')
  }
}


.check <- function(file,md5,token) {
  f_name = as.character(substitute(file))
  # 如果md5 一样,不用再保存
  if (md5 %in% records$md5) {
    e = which(records$md5 == md5)
    s <- list(
      f_name = f_name,
      save_time = records$save_time[e],
      re_time = records$re_time[e],
      token = records$token[e],
      status = 1)
  } else {
    # 如果 md5 不一样 但文件名和token一样；则判断是否update
    e = which(records$f_name == f_name & records$token == token)
    if (length(e) > 0) {
      s <- list(
        f_name = f_name,
        save_time = records$save_time[e],
        re_time = records$re_time[e],
        token = records$token[e],
        status = 2) # 2 for update
    } else {
    s <- list(
      status = 0
    )}
  }
  return(s)
}

.clean <- function(i){
  md5 = records$md5[i]
  try(file.remove(file.path(basepath,md5)))
}
