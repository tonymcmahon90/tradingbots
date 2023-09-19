#include <Trade\Trade.mqh>
CTrade trade;

input double _lotsize=0.01; // Lotsize
input int period=10; // RVI period
input bool zerofilter=true; // Filter above below 0 signals 

ulong _order=0;
int hRVI;
double bRVImain[],bRVIsignal[];

int OnInit()
{
   hRVI=iRVI(_Symbol,PERIOD_CURRENT,10);
   ArraySetAsSeries(bRVImain,true); // [0] newest    
   ArraySetAsSeries(bRVIsignal,true);
   return(INIT_SUCCEEDED);
}

bool SellSignal()
{
   if(zerofilter && bRVImain[1]<0) return false;
   
   if(bRVImain[1]<bRVIsignal[1] && bRVImain[2]>bRVIsignal[2]) return true; else return false;
}

bool BuySignal()
{
   if(zerofilter && bRVImain[1]>0) return false;
   
   if(bRVImain[1]>bRVIsignal[1] && bRVImain[2]<bRVIsignal[2]) return true; else return false;
}

void OnTick()
{
   double entry;
   CopyBuffer(hRVI,0,0,3,bRVImain);
   CopyBuffer(hRVI,1,0,3,bRVIsignal);
   
   if(_order!=0) // if got order check for close signal
   {   
      if(!PositionSelectByTicket(_order)){ _order=0; return; } // reset    
      
      // sell signal in buy  
      if(PositionGetInteger(POSITION_TYPE)==POSITION_TYPE_BUY)
      {
         if(SellSignal()) // sell signal
         {
            if(trade.PositionClose(_order)) _order=0;
         }
      }
      
      // buy signal in sell
      if(PositionGetInteger(POSITION_TYPE)==POSITION_TYPE_SELL)
      {
         if(BuySignal()) // buy signal
         {
            if(trade.PositionClose(_order)) _order=0;
         }
      }
   }   
   else // place order
   {     
      // pending buy signal if main crosses above signal
      if(BuySignal())      
      {
         entry=SymbolInfoDouble(_Symbol,SYMBOL_ASK); // change to pending 
         if(trade.Buy(_lotsize,_Symbol,entry,0,0,"Buy"))
         {
            if(trade.ResultRetcode()==TRADE_RETCODE_DONE) _order=trade.ResultOrder();
         }
      }
      
      // pending sell signal if main crosses below signal
      if(SellSignal())
      {
         entry=SymbolInfoDouble(_Symbol,SYMBOL_BID);
         if(trade.Sell(_lotsize,_Symbol,entry,0,0,"Sell"))
         {
            if(trade.ResultRetcode()==TRADE_RETCODE_DONE) _order=trade.ResultOrder();
         }
      }
   }
}