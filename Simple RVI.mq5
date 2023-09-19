#include <Trade\Trade.mqh>
CTrade trade;

input double _lotsize=0.01; // Lotsize
input int period=10; // RVI period
input group "optional filters"
input bool zerofilter=true; // Filter above below 0 signals 
input int stoploss=0; // Stoploss points or 0 
input bool useMA=false; // Use fast & slow MA filter
input ENUM_MA_METHOD ma_mode=MODE_EMA; // MA method
input int fastMA=20; // Fast MA period
input int slowMA=50; // Slow MA period

ulong _order=0;
int hRVI,hFastMA,hSlowMA;
double bRVImain[],bRVIsignal[],bFastMA[],bSlowMA[];

int OnInit()
{
   hRVI=iRVI(_Symbol,PERIOD_CURRENT,period);
   ArraySetAsSeries(bRVImain,true); // [0] newest    
   ArraySetAsSeries(bRVIsignal,true);
   
   hFastMA=iMA(_Symbol,PERIOD_CURRENT,fastMA,0,ma_mode,PRICE_TYPICAL);
   hSlowMA=iMA(_Symbol,PERIOD_CURRENT,slowMA,0,ma_mode,PRICE_TYPICAL);
   ArraySetAsSeries(bFastMA,true);
   ArraySetAsSeries(bSlowMA,true);
   return(INIT_SUCCEEDED);
}

bool BuySignal(bool exit)
{
   if(useMA && !exit) // only for entry signals trend filter
   {
      if(bFastMA[1]<bSlowMA[1]) return false; // want fast to be above for buy
   }

   if(zerofilter && bRVImain[1]>0) return false;
   
   if(bRVImain[1]>bRVIsignal[1] && bRVImain[2]<bRVIsignal[2]) return true; else return false;
}

bool SellSignal(bool exit)
{
   if(useMA && !exit)
   {
      if(bFastMA[1]>bSlowMA[1]) return false; // want fast to be below for sell
   }

   if(zerofilter && bRVImain[1]<0) return false;
   
   if(bRVImain[1]<bRVIsignal[1] && bRVImain[2]>bRVIsignal[2]) return true; else return false;
}

void OnTick()
{
   double entry,sl;
   CopyBuffer(hRVI,0,0,3,bRVImain);
   CopyBuffer(hRVI,1,0,3,bRVIsignal);
   
   CopyBuffer(hFastMA,0,0,3,bFastMA);
   CopyBuffer(hSlowMA,0,0,3,bSlowMA);
   
   if(_order!=0) // if got order check for close signal
   {   
      if(!PositionSelectByTicket(_order)){ _order=0; return; } // reset    
      
      // sell signal in buy  
      if(PositionGetInteger(POSITION_TYPE)==POSITION_TYPE_BUY)
      {
         if(SellSignal(true)) // sell signal
         {
            if(trade.PositionClose(_order)) _order=0;
         }
      }
      
      // buy signal in sell
      if(PositionGetInteger(POSITION_TYPE)==POSITION_TYPE_SELL)
      {
         if(BuySignal(true)) // buy signal
         {
            if(trade.PositionClose(_order)) _order=0;
         }
      }
   }   
   else // place order
   {     
      // pending buy signal if main crosses above signal
      if(BuySignal(false))      
      {
         entry=SymbolInfoDouble(_Symbol,SYMBOL_ASK); // change to pending 
         if(stoploss) sl=entry-(stoploss*_Point); else sl=0;
         if(trade.Buy(_lotsize,_Symbol,entry,sl,0,"Buy"))
         {
            if(trade.ResultRetcode()==TRADE_RETCODE_DONE) _order=trade.ResultOrder();
         }
      }
      
      // pending sell signal if main crosses below signal
      if(SellSignal(false))
      {
         entry=SymbolInfoDouble(_Symbol,SYMBOL_BID);
         if(stoploss) sl=entry+(stoploss*_Point); else sl=0;
         if(trade.Sell(_lotsize,_Symbol,entry,sl,0,"Sell"))
         {
            if(trade.ResultRetcode()==TRADE_RETCODE_DONE) _order=trade.ResultOrder();
         }
      }
   }
}