#include <Trade/Trade.mqh>
CTrade trade;

input double initlotsize=0.01; // Start lotsize
input double maxlotsize=1.0; // Max lotsize
input double increase=3; // Multiplier
input bool winreverse=false; // When you win flip direction
input bool losereverse=true; // When you lose flip direction
input bool addtowinner=true; // Increase winners 
input bool addtoloser=false; // Increase losers
input int _tp=100; // Take profit points
input int _sl=7000; // Stop loss points or 0

double lotsize;
bool buymode=true;
ulong _ticket;
double prev_balance,balance;

int OnInit()
{
   lotsize=initlotsize;
   _ticket=0;
   return(INIT_SUCCEEDED);
}

void OnTick()
{      
   double _entry,_stoploss,_takeprofit,_lotsize;

   if(_ticket==0)
   {
      _lotsize=NormalizeDouble(lotsize,2);
      if(buymode)
      {
         _entry=SymbolInfoDouble(_Symbol,SYMBOL_ASK);
         if(_sl!=0) _stoploss=_entry-(_sl*_Point); else _stoploss=0;
         _takeprofit=_entry+(_tp*_Point);         
         
         if(trade.Buy(_lotsize,_Symbol,_entry,_stoploss,_takeprofit,NULL))
         {
            if(trade.ResultRetcode()==TRADE_RETCODE_DONE)
            { 
               _ticket=trade.ResultOrder();    
               prev_balance=AccountInfoDouble(ACCOUNT_BALANCE);
            }            
         }  
      }
      else // sell mode 
      {
         _entry=SymbolInfoDouble(_Symbol,SYMBOL_BID);
         if(_sl!=0) _stoploss=_entry+(_sl*_Point); else _stoploss=0;
         _takeprofit=_entry-(_tp*_Point); 
         
         if(trade.Sell(_lotsize,_Symbol,_entry,_stoploss,_takeprofit,NULL))
         {
            if(trade.ResultRetcode()==TRADE_RETCODE_DONE)
            {
               _ticket=trade.ResultOrder();   
               prev_balance=AccountInfoDouble(ACCOUNT_BALANCE);
            }            
         }       
      }
   }     
   else // did it win or lose ? 
   {
      if(!PositionSelectByTicket(_ticket)) // position has closed 
      {  
         _ticket=0; 
         balance=AccountInfoDouble(ACCOUNT_BALANCE);
         
         if(balance>prev_balance) // winner, made money ( assume one trade at a time only ) 
         {
            Print("You Won");
            prev_balance=balance;    
            if(winreverse) buymode=!buymode; // flip on win
            if(addtowinner) lotsize*=increase; else lotsize=initlotsize; // add to winners        
         }
         else // lost money
         {
            Print("You Lose");
            prev_balance=balance;   
            if(losereverse) buymode=!buymode; // flip on lose
            if(addtoloser) lotsize*=increase; else lotsize=initlotsize; // add to losers
         }  
                  
         lotsize=MathMin(maxlotsize,lotsize); // max lotsize          
      } 
   } 
}
