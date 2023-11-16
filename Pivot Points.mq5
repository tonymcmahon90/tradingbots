#property indicator_chart_window
#property indicator_buffers 5
#property indicator_plots 5
#property indicator_label1 "Pivot Point"
#property indicator_color1 clrBlue
#property indicator_type1 DRAW_LINE
#property indicator_style1 STYLE_SOLID
#property indicator_width1 2
#property indicator_label2 "R1"
#property indicator_color2 clrOrange
#property indicator_type2 DRAW_LINE
#property indicator_style2 STYLE_SOLID
#property indicator_width2 2
#property indicator_label3 "S1"
#property indicator_color3 clrOrange
#property indicator_type3 DRAW_LINE
#property indicator_style3 STYLE_SOLID
#property indicator_width3 2
#property indicator_label4 "R0.5"
#property indicator_color4 clrRed
#property indicator_type4 DRAW_LINE
#property indicator_style4 STYLE_SOLID
#property indicator_width4 2
#property indicator_label5 "S0.5"
#property indicator_color5 clrRed
#property indicator_type5 DRAW_LINE
#property indicator_style5 STYLE_SOLID
#property indicator_width5 2

double pp[],r1[],s1[],r05[],s05[];

int OnInit()
{
   ChartRedraw(0);
   SetIndexBuffer(0,pp,INDICATOR_DATA);   ArraySetAsSeries(pp,true);   PlotIndexSetDouble(0,PLOT_EMPTY_VALUE,0.0);
   SetIndexBuffer(1,r1,INDICATOR_DATA);   ArraySetAsSeries(r1,true);   PlotIndexSetDouble(1,PLOT_EMPTY_VALUE,0.0);
   SetIndexBuffer(2,s1,INDICATOR_DATA);   ArraySetAsSeries(s1,true);   PlotIndexSetDouble(2,PLOT_EMPTY_VALUE,0.0);
   SetIndexBuffer(3,r05,INDICATOR_DATA);   ArraySetAsSeries(r05,true);   PlotIndexSetDouble(3,PLOT_EMPTY_VALUE,0.0);
   SetIndexBuffer(4,s05,INDICATOR_DATA);   ArraySetAsSeries(s05,true);   PlotIndexSetDouble(4,PLOT_EMPTY_VALUE,0.0);
   return(INIT_SUCCEEDED);
}
int OnCalculate(const int rates_total, const int prev_calculated, const datetime &time[], const double &open[],
                const double &high[], const double &low[], const double &close[], const long &tick_volume[],
                const long &volume[], const int &spread[])
{
   int limit=rates_total-prev_calculated,t,n;
   if(limit==0) limit++;
   
   double _pp,_r1,_s1;
   
   for(n=0;n<limit && !IsStopped();n++)
   {
      t=MathMin(iBarShift(NULL,PERIOD_D1,iTime(NULL,PERIOD_CURRENT,n),false)+1,iBars(NULL,PERIOD_D1)-1);
      _pp=(iClose(NULL,PERIOD_D1,t)+iHigh(NULL,PERIOD_D1,t)+iLow(NULL,PERIOD_D1,t))/3.0;
      _s1=(_pp*2.0)-iLow(NULL,PERIOD_D1,t);
      _r1=(_pp*2.0)-iHigh(NULL,PERIOD_D1,t);
      pp[n]=_pp;
      r1[n]=_r1;
      s1[n]=_s1;
      r05[n]=(pp[n]+r1[n])/2.0;
      s05[n]=(pp[n]+s1[n])/2.0;
   }
      
   Print(limit," ",n);   
   return(rates_total);
}