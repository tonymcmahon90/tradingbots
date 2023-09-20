#include <Trade\Trade.mqh>
CTrade trade;

input double _lotsize=0.01; // Lotsize
enum _c{RVI,MACD,Stochastic};
input _c _mode=RVI; // RVI or MACD or Stochastic
input group "RVI"
input int rvi_period=10; // RVI period
input group "MACD"
input int macd_fast=12; // MACD(fast)
input int macd_slow=26; // MACD(slow)
input int macd_signal=9; // MACD(signal)
input ENUM_APPLIED_PRICE macd_price=PRICE_CLOSE; // MACD price
input group "Stochastic"
input int stoch_k=8; // Stochastic(K)
input int stoch_d=3; // Stochastic(D)
input int stoch_slow=3; // Stochastic(slow)
input ENUM_MA_METHOD stoch_method=MODE_EMA; // Stochastic method
input ENUM_STO_PRICE stoch_price=STO_LOWHIGH; // Stochastic price
input group "optional filters"
input bool zerofilter=true; // Filter above below 0 signals ( 50 Stochastic )
input int stoploss=0; // Stoploss points or 0 
input bool useMA=false; // Use fast & slow MA filter
input ENUM_MA_METHOD ma_mode=MODE_EMA; // MA method
input int fastMA=20; // Fast MA period
input int slowMA=50; // Slow MA period

ulong _order=0;
int hRVI,hMACD,hSTOCH,hFastMA,hSlowMA;
double bRVImain[],bRVIsignal[],bMACDmain[],bMACDsignal[],bSTOCHmain[],bSTOCHsignal[],bFastMA[],bSlowMA[];

int OnInit()
{
   hRVI=iRVI(_Symbol,PERIOD_CURRENT,rvi_period);
   ArraySetAsSeries(bRVImain,true); // [0] newest    
   ArraySetAsSeries(bRVIsignal,true);
   
   hMACD=iMACD(_Symbol,PERIOD_CURRENT,macd_fast,macd_slow,macd_signal,macd_price);
   ArraySetAsSeries(bMACDmain,true);
   ArraySetAsSeries(bMACDsignal,true);
   
   hSTOCH=iStochastic(_Symbol,PERIOD_CURRENT,stoch_k,stoch_d,stoch_slow,stoch_method,stoch_price);
   ArraySetAsSeries(bSTOCHmain,true);
   ArraySetAsSeries(bSTOCHsignal,true);
   
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

   if(_mode==RVI)
   {
      if(zerofilter && bRVImain[1]>0) return false;   
      if(bRVImain[1]>bRVIsignal[1] && bRVImain[2]<bRVIsignal[2]) return true; else return false;   
   }
   else if(_mode==MACD)
   {
      if(zerofilter && bMACDmain[1]>0) return false;   
      if(bMACDmain[1]>bMACDsignal[1] && bMACDmain[2]<bMACDsignal[2]) return true; else return false;   
   }
   else if(_mode==Stochastic)
   {
      if(zerofilter && bSTOCHmain[1]>50) return false;   
      if(bSTOCHmain[1]>bSTOCHsignal[1] && bSTOCHmain[2]<bSTOCHsignal[2]) return true; else return false;   
   }
   
   return false;
}

bool SellSignal(bool exit)
{
   if(useMA && !exit)
   {
      if(bFastMA[1]>bSlowMA[1]) return false; // want fast to be below for sell
   }
   
   if(_mode==RVI)
   {
      if(zerofilter && bRVImain[1]<0) return false;   
      if(bRVImain[1]<bRVIsignal[1] && bRVImain[2]>bRVIsignal[2]) return true; else return false;   
   }
   else if(_mode==MACD)
   {
      if(zerofilter && bMACDmain[1]<0) return false;   
      if(bMACDmain[1]<bMACDsignal[1] && bMACDmain[2]>bMACDsignal[2]) return true; else return false;   
   }
   else if(_mode==Stochastic)
   {
      if(zerofilter && bSTOCHmain[1]<50) return false;   
      if(bSTOCHmain[1]<bSTOCHsignal[1] && bSTOCHmain[2]>bSTOCHsignal[2]) return true; else return false;   
   }  
   
   return false; 
}

void OnTick()
{
   double entry,sl;
   CopyBuffer(hRVI,0,0,3,bRVImain);
   CopyBuffer(hRVI,1,0,3,bRVIsignal);
   
   CopyBuffer(hMACD,0,0,3,bMACDmain);
   CopyBuffer(hMACD,1,0,3,bMACDsignal);
   
   CopyBuffer(hSTOCH,0,0,3,bSTOCHmain);
   CopyBuffer(hSTOCH,1,0,3,bSTOCHsignal);
   
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