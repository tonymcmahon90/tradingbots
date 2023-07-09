// 9th July 2023
// MACD EMA with Histograms 
#include <MovingAverages.mqh>

#property indicator_separate_window
#property indicator_buffers 8
#property indicator_plots   6
#property indicator_type1   DRAW_LINE
#property indicator_type2   DRAW_LINE
#property indicator_type3   DRAW_HISTOGRAM
#property indicator_type4   DRAW_HISTOGRAM
#property indicator_type5   DRAW_HISTOGRAM
#property indicator_type6   DRAW_HISTOGRAM
#property indicator_color1  clrBlue
#property indicator_color2  clrOrangeRed
#property indicator_color3  clrRed
#property indicator_color4  clrGreen
#property indicator_color5  clrSalmon
#property indicator_color6  clrLightGreen
#property indicator_width1  2
#property indicator_width2  2
#property indicator_width3  2
#property indicator_width4  2
#property indicator_width5  2
#property indicator_width6  2
#property indicator_label1  "MACD"
#property indicator_label2  "Signal"
#property indicator_label3  "Hist1"
#property indicator_label4  "Hist2"
#property indicator_label5  "Hist3"
#property indicator_label6  "Hist4"
#property indicator_level1  0

input int FastEMA=12;       
input int SlowEMA=26;              
input int SignalEMA=9;            
input ENUM_APPLIED_PRICE AppliedPrice=PRICE_CLOSE;  
 
double MacdBuffer[];
double SignalBuffer[];
double FastMaBuffer[];
double SlowMaBuffer[];
double Hist1[],Hist2[],Hist3[],Hist4[];

int FastMaHandle;
int SlowMaHandle;

void OnInit()
{
   SetIndexBuffer(0,MacdBuffer,INDICATOR_DATA);
   SetIndexBuffer(1,SignalBuffer,INDICATOR_DATA);
   SetIndexBuffer(2,Hist1,INDICATOR_DATA);
   SetIndexBuffer(3,Hist2,INDICATOR_DATA);
   SetIndexBuffer(4,Hist3,INDICATOR_DATA);
   SetIndexBuffer(5,Hist4,INDICATOR_DATA);
   SetIndexBuffer(6,FastMaBuffer,INDICATOR_CALCULATIONS);
   SetIndexBuffer(7,SlowMaBuffer,INDICATOR_CALCULATIONS);
   
   PlotIndexSetInteger(1,PLOT_DRAW_BEGIN,SignalEMA-1); // need to use EMA on MacdBuffer
   PlotIndexSetInteger(2,PLOT_DRAW_BEGIN,SignalEMA-1);
   PlotIndexSetInteger(3,PLOT_DRAW_BEGIN,SignalEMA-1);
   PlotIndexSetInteger(4,PLOT_DRAW_BEGIN,SignalEMA);
   PlotIndexSetInteger(5,PLOT_DRAW_BEGIN,SignalEMA);
   string short_name=StringFormat("MACD(%d,%d,%d)",FastEMA,SlowEMA,SignalEMA);
   IndicatorSetString(INDICATOR_SHORTNAME,short_name);
   FastMaHandle=iMA(NULL,0,FastEMA,0,MODE_EMA,AppliedPrice);
   SlowMaHandle=iMA(NULL,0,SlowEMA,0,MODE_EMA,AppliedPrice);
}
int OnCalculate(const int rates_total,                const int prev_calculated,                const datetime &time[],                const double &open[],
                const double &high[],                const double &low[],                const double &close[],                const long &tick_volume[],
                const long &volume[],                const int &spread[])
{
   if(rates_total<SignalEMA) return(0);
   int calculated=BarsCalculated(FastMaHandle);
   if(calculated<rates_total)
   {
      Print("Not all data of FastMaHandle is calculated (",calculated," bars). Error ",GetLastError());
      return(0);
   }
   calculated=BarsCalculated(SlowMaHandle);
   if(calculated<rates_total)
   {
      Print("Not all data of SlowMaHandle is calculated (",calculated," bars). Error ",GetLastError());
      return(0);
   }
   
   int to_copy;
   if(prev_calculated>rates_total || prev_calculated<0)
      to_copy=rates_total;
   else
     {
      to_copy=rates_total-prev_calculated;
      if(prev_calculated>0)
         to_copy++;
     }
 
   if(IsStopped())  
      return(0);
   if(CopyBuffer(FastMaHandle,0,0,to_copy,FastMaBuffer)<=0)
     {
      Print("Getting fast EMA is failed! Error ",GetLastError());
      return(0);
     }
 
   if(IsStopped()) // checking for stop flag
      return(0);
   if(CopyBuffer(SlowMaHandle,0,0,to_copy,SlowMaBuffer)<=0)
     {
      Print("Getting slow SMA is failed! Error ",GetLastError());
      return(0);
     }
 
   int start;
   if(prev_calculated==0)
      start=0;
   else
      start=prev_calculated-1;
 
   int i;
   double tmp;
   
   for(i=start; i<rates_total && !IsStopped(); i++)
      MacdBuffer[i]=FastMaBuffer[i]-SlowMaBuffer[i];
 
   ExponentialMAOnBuffer(rates_total,prev_calculated,0,SignalEMA,MacdBuffer,SignalBuffer);
   
   for(i=start; i<rates_total && !IsStopped(); i++)
   {  
      tmp=MacdBuffer[i]-SignalBuffer[i];
      if(tmp>0) Hist1[i]=tmp; else Hist2[i]=tmp;       
   }
   
   for(i=start; i<rates_total && !IsStopped(); i++)
   {
      if(i>SignalEMA)
      {
         if(Hist1[i]<Hist1[i-1]) Hist3[i]=Hist1[i];         
         if(Hist2[i]>Hist2[i-1]) Hist4[i]=Hist2[i];
         
         if(Hist1[i]>Hist3[i]) Hist3[i]=0; // clear old lower than
         if(Hist2[i]<Hist4[i]) Hist4[i]=0;
      }
   }    
 
   return(rates_total);
}