// 6th July 2023
// click trade calculates lotsize 

#property strict

input double riskpercent=1; // Risk %
input double cashrisk=0; // Cash risk or 0 to use % risk 
input int slippage=10; // Slippage

enum _mode{NO,ENTRY,STOPLOSS,TAKEPROFIT,EXPIRY} mode;
double entry,stoploss,takeprofit,lotsize;
datetime expiry;
long chartid;

int OnInit()
{
   chartid=ChartID();
   ObjectCreate(chartid,"stoploss",OBJ_HLINE,0,0,0);
   ObjectSetInteger(chartid,"stoploss",OBJPROP_COLOR,clrRed);
   ObjectSetInteger(chartid,"stoploss",OBJPROP_STYLE,STYLE_DOT);
   ObjectCreate(chartid,"entry",OBJ_HLINE,0,0,0);
   ObjectSetInteger(chartid,"entry",OBJPROP_COLOR,clrBlue);
   ObjectSetInteger(chartid,"entry",OBJPROP_STYLE,STYLE_DOT);
   ObjectCreate(chartid,"takeprofit",OBJ_HLINE,0,0,0);
   ObjectSetInteger(chartid,"takeprofit",OBJPROP_COLOR,clrGreen);
   ObjectSetInteger(chartid,"takeprofit",OBJPROP_STYLE,STYLE_DOT);
   ObjectCreate(chartid,"expiry",OBJ_VLINE,0,0,0);
   ObjectSetInteger(chartid,"expiry",OBJPROP_COLOR,clrRed);
   ObjectSetInteger(chartid,"expiry",OBJPROP_STYLE,STYLE_DOT);
   
   return(INIT_SUCCEEDED);
}
void OnDeinit(const int reason)
{
   ObjectDelete(chartid,"stoploss");
   ObjectDelete(chartid,"entry");
   ObjectDelete(chartid,"takeprofit");
   ObjectDelete(chartid,"expiry");
}
void OnTick()
{   
}
void OnChartEvent(const int id, const long &lparam, const double &dparam, const string &sparam)
{
   int window;
   datetime time;
   double price;
   
   if(id==CHARTEVENT_KEYDOWN)
   {
      switch((int)lparam)
      {
         case 'E': Print("Next click entry price"); mode=ENTRY; break;
         case 'S': Print("Next click stoploss price"); mode=STOPLOSS; break;
         case 'T': Print("Next click takeprofit price"); mode=TAKEPROFIT; break;
         case 'X': Print("Next click expiry time"); mode=EXPIRY; break;
         case 'P': PlaceTrade(); break;
         case 'R': Print("Reset"); Reset(); break;
      }
   }

   if(id==CHARTEVENT_CLICK)
   {
      ChartXYToTimePrice(chartid,(int)lparam,(int)dparam,window,time,price);
      
      if(mode==ENTRY){ entry=NormalizeDouble(price,_Digits); Print("New entry ",DoubleToString(entry,_Digits)); ObjectSetDouble(chartid,"entry",OBJPROP_PRICE,entry); ShowLotsize(); mode=NO; }
      if(mode==STOPLOSS){ stoploss=NormalizeDouble(price,_Digits); Print("New stoploss ",DoubleToString(stoploss,_Digits)); ObjectSetDouble(chartid,"stoploss",OBJPROP_PRICE,stoploss); ShowLotsize(); mode=NO; }
      if(mode==TAKEPROFIT){ takeprofit=NormalizeDouble(price,_Digits); Print("New takeprofit ",DoubleToString(takeprofit,_Digits)); ObjectSetDouble(chartid,"takeprofit",OBJPROP_PRICE,takeprofit); ShowLotsize(); mode=NO; }
      if(mode==EXPIRY){ expiry=time; Print("New expiry ",TimeToString(expiry,TIME_DATE|TIME_MINUTES)); ObjectSetInteger(chartid,"expiry",OBJPROP_TIME,expiry); mode=NO; }
   }

}

void Reset()
{
   entry=stoploss=takeprofit=0; expiry=0;
   ObjectSetDouble(chartid,"entry",OBJPROP_PRICE,entry);
   ObjectSetDouble(chartid,"stoploss",OBJPROP_PRICE,stoploss);
   ObjectSetDouble(chartid,"takeprofit",OBJPROP_PRICE,takeprofit);
   ObjectSetInteger(chartid,"expiry",OBJPROP_TIME,expiry);
}

void ShowLotsize()
{
   if(stoploss==0){ Print("No stoploss"); return; } // need a stoploss   
   if(entry==0 && stoploss<Bid)entry=Ask; // buy
   if(entry==0 && stoploss>Ask)entry=Bid; // sell
   if(entry==0){ Print("Stoploss between Ask and Bid error"); return; } // stoploss between Ask and Bid error
   
   // difference in price , ticks
   double price_difference=NormalizeDouble(MathAbs(entry-stoploss),_Digits);
   double ticks=NormalizeDouble(price_difference/SymbolInfoDouble(Symbol(),SYMBOL_TRADE_TICK_SIZE),_Digits);
   Print("Price difference ",DoubleToString(price_difference,_Digits)," Ticks ",ticks);
   
   // ideal lotsize
   double risk_money=0;
   if(cashrisk!=0) risk_money=cashrisk; else risk_money=AccountBalance()*riskpercent*0.01; // risk in money
   
   double tick_value=SymbolInfoDouble(Symbol(),SYMBOL_TRADE_TICK_VALUE);
   double ideal_lotsize=risk_money/(tick_value*ticks);
   
   Print("Ideal Cash Risk ",DoubleToString(risk_money,2)," ",AccountCurrency()," Tick value ",DoubleToString(tick_value,2)," ",AccountCurrency()," Ideal lotsize ",DoubleToString(ideal_lotsize,3));
   
   double tmp_lotsize=SymbolInfoDouble(Symbol(),SYMBOL_VOLUME_MIN),use_lotsize=0;
   
   if(tmp_lotsize>ideal_lotsize){ Print("Not enough for minimum lotsize ",tmp_lotsize); return; }
   
   while(true)
   {
      if(tmp_lotsize>ideal_lotsize) break; // break if gone over
      if(tmp_lotsize>SymbolInfoDouble(Symbol(),SYMBOL_VOLUME_MAX)) break; // break if > MAX
      use_lotsize=tmp_lotsize; // update 
      tmp_lotsize+=SymbolInfoDouble(Symbol(),SYMBOL_VOLUME_STEP); // next step
   }
   
   lotsize=NormalizeDouble(use_lotsize,2);
   double risk=lotsize*tick_value*ticks; // cash risk using lotsize
 
   // takeprofit
   
   if(takeprofit!=0)
   {
      if(!OrderCheck()) return; 
      double takeprofit_ratio=NormalizeDouble(MathAbs(entry-takeprofit),_Digits)/price_difference;   
      Print("Useable lotsize ",lotsize," Risk ",DoubleToString(risk,2)," Take profit ",DoubleToString(risk*takeprofit_ratio,2) );
   }
   else
      Print("Useable lotsize ",lotsize," Risk ",DoubleToString(risk,2) );
}

void PlaceTrade()
{
   if(lotsize==0){ Print("Lotsize error"); return; }
   
   int ret;
 
   if(stoploss<entry && entry<Ask) // buy limit
   {
      ret=OrderSend(Symbol(),OP_BUYLIMIT,lotsize,entry,slippage,stoploss,takeprofit,NULL,0,expiry,clrNONE);
      if(ret==-1){ Print("Buy Limit error ",GetLastError()); return; }   
      return;
   }  
   
   if(stoploss<entry && entry>Ask) // buy stop
   {
      ret=OrderSend(Symbol(),OP_BUYSTOP,lotsize,entry,slippage,stoploss,takeprofit,NULL,0,expiry,clrNONE);
      if(ret==-1){ Print("Buy Stop error ",GetLastError()); return; }   
      return;
   }  
   
   if(stoploss>entry && entry>Bid) // sell limit
   {
      ret=OrderSend(Symbol(),OP_SELLLIMIT,lotsize,entry,slippage,stoploss,takeprofit,NULL,0,expiry,clrNONE);
      if(ret==-1){ Print("Sell limit error ",GetLastError()); return; }   
      return;
   }   
   
   if(stoploss>entry && entry<Bid) // sell stop
   {
      ret=OrderSend(Symbol(),OP_SELLSTOP,lotsize,entry,slippage,stoploss,takeprofit,NULL,0,expiry,clrNONE);
      if(ret==-1){ Print("Sell stop error ",GetLastError()); return; }   
      return;
   } 
   
   if(stoploss<entry && entry==Ask) // buy at market 
   {
      ret=OrderSend(Symbol(),OP_BUY,lotsize,entry,slippage,stoploss,takeprofit,NULL,0,expiry,clrNONE);
      if(ret==-1){ Print("Buy error ",GetLastError()); return; }   
      return;
   }
   
   if(stoploss>entry && entry==Bid) // sell at market 
   {
      ret=OrderSend(Symbol(),OP_SELL,lotsize,entry,slippage,stoploss,takeprofit,NULL,0,expiry,clrNONE);
      if(ret==-1){ Print("Sell error ",GetLastError()); return; }   
      return;
   }  
      
}

bool OrderCheck() // check order for correct takeprofit 
{
   if(stoploss<entry && takeprofit<entry){ Print("Takeprofit wrong place"); return false; }
   if(stoploss>entry && takeprofit>entry){ Print("Takeprofit wrong place"); return false; }
   
   return true;
}