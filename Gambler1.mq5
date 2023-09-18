#include <Trade\Trade.mqh>
CTrade trade;

ulong ticket=0;
double balance,lotsize;
enum d{BUY,SELL}direction;

input double startlotsize=0.01;
input double multiplier=3;
input double maxlot=0.5;
input int sl=6000;
input int tp=300;

int OnInit()
{
   balance=AccountInfoDouble(ACCOUNT_BALANCE); // assume only robot running 
   direction=BUY;
   lotsize=startlotsize;
   return(INIT_SUCCEEDED);
}

void OnTick()
{
   if(ticket==0)
   {
      if(AccountInfoDouble(ACCOUNT_BALANCE)<balance) // lost money so flip 
      {
         if(direction==BUY) direction=SELL; else direction=BUY; 
         lotsize=startlotsize;
      }
      else if(AccountInfoDouble(ACCOUNT_BALANCE)>balance) lotsize*=multiplier; // won 
      
      balance=AccountInfoDouble(ACCOUNT_BALANCE);
      lotsize=NormalizeDouble(MathMin(maxlot,lotsize),2);
      
      if(direction==BUY)
      {
         if(trade.Buy(lotsize,_Symbol,SymbolInfoDouble(_Symbol,SYMBOL_ASK),
            SymbolInfoDouble(_Symbol,SYMBOL_ASK)-(sl*_Point),SymbolInfoDouble(_Symbol,SYMBOL_ASK)+(tp*_Point),"Buy"))
         {
            if(trade.ResultRetcode()==TRADE_RETCODE_DONE) ticket=trade.ResultOrder();
         }      
      } // else SELL
      else
      {
         if(trade.Sell(lotsize,_Symbol,SymbolInfoDouble(_Symbol,SYMBOL_BID),
            SymbolInfoDouble(_Symbol,SYMBOL_BID)+(sl*_Point),SymbolInfoDouble(_Symbol,SYMBOL_BID)-(tp*_Point),"Sell"))
         {
            if(trade.ResultRetcode()==TRADE_RETCODE_DONE) ticket=trade.ResultOrder();
         } 
      }
   }
   else
   {
      if(!PositionSelectByTicket(ticket)) ticket=0; // Position close so place new trade
   }
}