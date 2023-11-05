#include <Trade/Trade.mqh>
CTrade trade;

input int _tp=0; // Takeprofit scalper 
input int _sl=0; // Stoploss scalper
input int nadx=10; // ADX period
input int adx=22; // ADX trend level above

int hADX;
double bADXmain[],bADXpD[],bADXmD[];
ulong _ticket,_type;

int OnInit()
{
   hADX=iADX(NULL,0,nadx);
   ArraySetAsSeries(bADXmain,true);
   ArraySetAsSeries(bADXpD,true);
   ArraySetAsSeries(bADXmD,true);
   return(INIT_SUCCEEDED);
}
void OnDeinit(const int reason)
{
}
void OnTick()
{   
 // static datetime t=iTime(NULL,0,0);  if(iTime(NULL,0,0)==t) return; else t=iTime(NULL,0,0); // only when got new candle as [0]
   
   CopyBuffer(hADX,0,0,3,bADXmain);
   CopyBuffer(hADX,1,0,3,bADXpD);
   CopyBuffer(hADX,2,0,3,bADXmD);
   double entry=0,takeprofit=0,stoploss=0;
   
   if(bADXmain[0]>adx && bADXmain[0]>bADXmain[1] ) // trending, sloping
   {
      if(!PositionSelectByTicket(_ticket)) _ticket=0; 
   
      if(_ticket) // see if should stay in trade
      {
         if(PositionSelectByTicket(_ticket)) _type=PositionGetInteger(POSITION_TYPE); else return; 
         
         if(_type==POSITION_TYPE_BUY)
         {
            if(bADXpD[0]>bADXmD[0]) return; 
         }
         
         if(_type==POSITION_TYPE_SELL)
         {
            if(bADXpD[0]<bADXmD[0]) return; 
         }
            
         if(trade.PositionClose(_ticket)) _ticket=0; 
         return; 
      }
      
      if(bADXpD[0]>bADXmD[0]) // buy if no ticket
      {
         entry=SymbolInfoDouble(_Symbol,SYMBOL_ASK);
         if(_tp)takeprofit=entry+(_tp*_Point);
         if(_sl)stoploss=entry-(_sl*_Point);
         
         if(trade.Buy(0.1,NULL,entry,stoploss,takeprofit,NULL))
         {
            if(trade.ResultRetcode()==TRADE_RETCODE_DONE) _ticket=trade.ResultOrder();
         }
      }
      
      if(bADXpD[0]<bADXmD[0]) // sell if not ticket 
      {
         entry=SymbolInfoDouble(_Symbol,SYMBOL_BID);
         if(_tp)takeprofit=entry-(_tp*_Point);
         if(_sl)stoploss=entry+(_sl*_Point);
      
         if(trade.Sell(0.1,NULL,entry,stoploss,takeprofit,NULL))
         {
            if(trade.ResultRetcode()==TRADE_RETCODE_DONE) _ticket=trade.ResultOrder();
         }
      }   
   }
   else // not trending 
   {
      if(!PositionSelectByTicket(_ticket)){ _ticket=0; return; }
      if(_ticket){ if(trade.PositionClose(_ticket)) _ticket=0; }     
   }   
}