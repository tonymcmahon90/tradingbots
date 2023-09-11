
void OnStart()
{
   int shift=-120*60; // Time shift minutes

   int bars=Bars(_Symbol,_Period);
   string filename=_Symbol+(string)(PeriodSeconds(_Period)/60)+".csv";
   Print(filename," ",bars," shift ",shift," period minutes ",PeriodSeconds(_Period)/60);
   
   int hFile=FileOpen(filename,FILE_WRITE|FILE_CSV|FILE_ANSI,",");
   if(hFile==INVALID_HANDLE){ Print("FileOpen error ",GetLastError()); return; }
   
   for(int n=bars-1;n>=0;n--)
   {
      if(iOpen(_Symbol,_Period,n)!=0)
         FileWrite(hFile,TimeToString(iTime(_Symbol,_Period,n)+(datetime)shift,TIME_DATE),TimeToString(iTime(_Symbol,_Period,n)+(datetime)shift,TIME_MINUTES),
                         DoubleToString(iOpen(_Symbol,_Period,n),_Digits),DoubleToString(iHigh(_Symbol,_Period,n),_Digits),
                         DoubleToString(iLow(_Symbol,_Period,n),_Digits),DoubleToString(iClose(_Symbol,_Period,n),_Digits),iTickVolume(_Symbol,_Period,n));   
         
      if(n%1000==0)Print(n);
   }
   FileClose(hFile);   
}
