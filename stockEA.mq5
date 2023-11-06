#include <Trade/Trade.mqh>
CTrade trade;

int hStoch,hMA;
double bStochMain[],bMA[];

input int _sl=500; // stoploss points
input double buyat=20;
input double sellat=80;
input double buyexit=75;
input double sellexit=25;
input double lotsize=0.1;
input int ma=30; // MA period

ulong _ticket,_type;

int OnInit()
{
   hStoch=iStochastic(NULL,0,5,3,3,MODE_SMA,STO_LOWHIGH);
   hMA=iMA(NULL,0,ma,0,MODE_SMA,PRICE_TYPICAL);
   ArraySetAsSeries(bStochMain,true); 
   ArraySetAsSeries(bMA,true); 
   return(INIT_SUCCEEDED);
}

void OnTick()
{
   CopyBuffer(hStoch,0,0,3,bStochMain);
   CopyBuffer(hMA,0,0,3,bMA);
  
   double entry,stoploss=0,takeprofit=0;    
            
   if(_ticket==0)
   {   
      if(bStochMain[1]>buyat && bStochMain[2]<buyat && iClose(NULL,0,1)>bMA[1] && bMA[1]>bMA[2])
      {
         entry=SymbolInfoDouble(Symbol(),SYMBOL_ASK);
         if(_sl)stoploss=entry-(_sl*_Point);
         if(trade.Buy(lotsize,Symbol(),entry,stoploss,takeprofit,NULL))
         {
            if(trade.ResultRetcode()==TRADE_RETCODE_DONE) _ticket=trade.ResultOrder();
         }
      }
   
      if(bStochMain[1]<sellat && bStochMain[2]>sellat && iClose(NULL,0,1)<bMA[1] && bMA[1]<bMA[2])
      {
         entry=SymbolInfoDouble(Symbol(),SYMBOL_BID);
         if(_sl)stoploss=entry+(_sl*_Point);
         if(trade.Sell(lotsize,Symbol(),entry,stoploss,takeprofit,NULL))
         {
            if(trade.ResultRetcode()==TRADE_RETCODE_DONE) _ticket=trade.ResultOrder();
         }
      }
   }
   else // got ticket so close if not valid 
   {
      if(!PositionSelectByTicket(_ticket)){ _ticket=0; return; } // closed tp or sl 
   
      if(PositionSelectByTicket(_ticket)) _type=PositionGetInteger(POSITION_TYPE); else return; 
   
      if(_type==POSITION_TYPE_BUY)
      {
         if(bStochMain[1]>buyexit && bStochMain[2]<buyexit)         
            if(trade.PositionClose(_ticket)){ _ticket=0; return; } // close
      }
      
      if(_type==POSITION_TYPE_SELL)
      {
         if(bStochMain[1]<sellexit && bStochMain[2]>sellexit)
            if(trade.PositionClose(_ticket)){ _ticket=0; return; } // close
      }
   }   
}