#include <Controls\Button.mqh>
#include <Trade\Trade.mqh>

CTrade trade;

#define BTN_BUY_NAME "Btn Buy"
#define BTN_SELL_NAME "Btn Sell"
#define BTN_CLOSE_NAME "Btn Close"

CButton btnBuy;
CButton btnSell;
CButton btnClose;

int OnInit()
{
   int width=(int)ChartGetInteger(0,CHART_WIDTH_IN_PIXELS,0);

   btnBuy.Create(0,BTN_BUY_NAME,0,width-200,100,width-100,150); btnBuy.Text("Buy");
   btnSell.Create(0,BTN_SELL_NAME,0,width-200,160,width-100,210); btnSell.Text("Sell");
   btnClose.Create(0,BTN_CLOSE_NAME,0,width-200,220,width-100,270); btnClose.Text("Close");
   
   ChartRedraw(0);
   return(INIT_SUCCEEDED);
}
void OnDeinit(const int reason)
{   
   btnBuy.Destroy(reason);
   btnSell.Destroy(reason);
   btnClose.Destroy(reason);
}
void OnTick()
{
   if(btnBuy.Pressed()){ trade.Buy(0.1); btnBuy.Pressed(false); }
   if(btnSell.Pressed()){ trade.Sell(0.1); btnSell.Pressed(false); }
   if(btnClose.Pressed())
   { 
      for(int n=PositionsTotal()-1;n>=0;n--){
         ulong _ticket=PositionGetTicket(n);
         trade.PositionClose(_ticket); 
      }
      btnClose.Pressed(false); 
   }
}