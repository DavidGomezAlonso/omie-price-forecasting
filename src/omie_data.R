
# ------------------------------------------------------------
# 1. Download day file
# ------------------------------------------------------------

download_omie=function(date,download_folder){
  date=as.Date(date)
  for (i in 1:4){
    name=sprintf("marginalpdbc_%s.%d",format(date,"%Y%m%d"),i)
    url=paste0("https://www.omie.es/es/file-download?parents=marginalpdbc&filename=",name)
    file_path=paste0(download_folder,"/",name)
    download=try(download.file(url,destfile = file_path,mode = "wb",method = "libcurl",quiet=TRUE),silent = TRUE)
    if(!inherits(download,"try-error")){
      return(file_path)
    }
  }
    
}
  
  
  

# ------------------------------------------------------------
# 2. Read OMIE file
# ------------------------------------------------------------ 
read_omie_file=function(file_path){
  read_file=readLines(file_path,warn=FALSE)
  read_file=read_file[-c(1,length(read_file))]
  data=read.table(text=read_file,sep=";",fill = TRUE,stringsAsFactors = FALSE)
  data=data$V6
  ## Standard time transition Summer -> Winter
  if(length(data)==100){
    data[9]=mean(c(data[9],data[13]))
    data[10]=mean(c(data[10],data[14]))
    data[11]=mean(c(data[11],data[15]))
    data[12]=mean(c(data[12],data[16]))
    data=data[-c(13,14,15,16)]
  }
  ## Standard time transition Winter -> Summer
  if(length(data)==92){
    interpolated_values=seq(data[8],data[9],length.out=6)[2:5]
    data=c(data[1:8],interpolated_values,data[9:92])
    
    
    
  }

  return(data)
}

# ------------------------------------------------------------
# 3. Get / update data
# ------------------------------------------------------------


get_data=function(download_folder="data/Omie"){
  start_date=as.Date("2025-10-01")
  end_date=Sys.Date()
  ### Data path
  file_path=file.path(download_folder,"omie_file.rds")
  ### 1. Folder creation
  if(!dir.exists(download_folder)){
    dir.create(download_folder,recursive=TRUE)
  }
  ### 2. Create file if it does not exist
  if(!file.exists(file_path)){
    message("Generating complete file")
    dates=seq(start_date,end_date,by="day")
    omie_file=matrix(numeric(0),nrow=96,ncol=0)
    rownames(omie_file)=format(seq(from = as.POSIXct("2000-01-01 00:00:00"),
        by = "15 min",
        length.out = 96
      ),"%H:%M")
    for(i in seq_along(dates)){
      date=dates[i]
      column=read_omie_file(download_omie(date,download_folder))
      omie_file=cbind(omie_file,column)
      colnames(omie_file)[ncol(omie_file)]=format(date,"%d/%m/%y")
    }
    saveRDS(omie_file,file_path)
    return(omie_file)
  }
  # Update data
  else{
    omie_file=readRDS(file_path)
    last_date=colnames(omie_file)[ncol(omie_file)]
    last_date=as.Date(last_date, format = "%d/%m/%y")
    # If the file is up to date, leave it unchanged
    if(end_date==last_date){
      return(omie_file)
    }
    # Update data
    else{
      dates=seq(last_date+1,end_date,by="day")
    for (i in seq_along(dates)){
      date=dates[i]
      column=read_omie_file(download_omie(date,download_folder))
      omie_file=cbind(omie_file,column)
      colnames(omie_file)[ncol(omie_file)]=format(date,"%d/%m/%y")
    }
    saveRDS(omie_file,file_path)
    return(omie_file)}
    
    
    
  }
  
  
  
  
  
  
  
  
}

