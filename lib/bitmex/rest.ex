defmodule Bitmex.Rest do
  @moduledoc """
  BitMEX Rest API client.
  """

  require Logger
  import Bitmex.Rest.Client, only: [auth_get: 2, auth_post: 2, auth_put: 2,
                                    auth_delete: 2, non_auth_get: 2]

  defmodule Order do
    @doc """
    Get your orders.
    """
    def get(params \\ []) do
      auth_get("/order", params)
    end

    @doc """
    Create a new order.
    """
    def create(params) do
      auth_post("/order", params)
    end

    @doc """
    Create multiple new orders.
    """
    def create_bulk(params) do
      auth_post("/order/bulk", params)
    end

    @doc """
    Amend the quantity or price of an open order.
    """
    def update(params) do
      auth_put("/order", params)
    end

    @doc """
    Amend multiple orders.
    """
    def update_bulk(params) do
      auth_put("/order/bulk", params)
    end

    @doc """
    Cancel orders. Send multiple order IDs to cancel in bulk.
    """
    def delete(params) do
      auth_delete("/order", params)
    end

    @doc """
    Cancels all of your orders.
    """
    def delete_all(params \\ []) do
      auth_delete("/order/all", params)
    end

    @doc """
    Automatically cancel all your orders after a specified timeout.
    """
    def cancel_all_after(params) do
      auth_post("/order/cancelAllAfter", params)
    end
  end

  defmodule Position do
    @doc """
    Get your positions.
    """
    def get(params \\ []) do
      auth_get("/position", params)
    end

    @doc """
    Enable isolated margin or cross margin per-position.
    """
    def isolate(params) do
      auth_post("/position/isolate", params)
    end
        
    @doc """
    Choose leverage for a position.
    """
    def leverage(params) do
      auth_post("/position/leverage", params)
    end

    @doc """
    Update your risk limit.
    """
    def risk_limit(params) do
      auth_post("/position/riskLimit", params)
    end

    @doc """
    Transfer equity in or out of a position.
    """
    def transfer_margin(params) do
      auth_post("/position/transferMargin", params)
    end
  end

  defmodule Execution do
    @doc """
    Get all raw executions for your account.
    """
    def get(params) do
      auth_get("/execution", params)
    end

    @doc """
    Get all balance-affecting executions.
    
    This includes each trade, insurance charge, and settlement.
    """
    def trade_history(params) do
      auth_get("/execution/tradeHistory", params)
    end
  end

  defmodule User do
    @doc """
    Get your user model.
    """
    def get(params \\ []) do
      auth_get("/user", params)
    end

    @doc """
    Get your account's commission status.
    """
    def commission(params \\ []) do
      auth_get("/user/commission", params)
    end

    @doc """
    Get your account's margin status.
    
    Send a currency of "all" to receive an array of all supported currencies.
    """
    def margin(params \\ []) do
      auth_get("/user/margin", params)
    end

    @doc """
    Get your current wallet information.
    """
    def wallet(params \\ []) do
      auth_get("/user/wallet", params)
    end

    @doc """
    Get a history of all of your wallet transactions.
    """
    def wallet_history(params \\ []) do
      auth_get("/user/walletHistory", params)
    end

    @doc """
    Get a summary of all of your wallet transactions.
    """
    def wallet_summary(params \\ []) do
      auth_get("/user/walletSummary", params)
    end
  end

  defmodule Liquidation do
    @doc """
    Get liquidation orders
    """
    def get(params \\ []) do
      non_auth_get("/liquidation", params)
    end
  end

  defmodule OrderBook do
    @doc """
    Get current orderbook in vertical format.

    `symbol` is a required argument.
    """
    def get(params) do
      non_auth_get("/orderBook/L2", params)
    end
  end

  defmodule Funding do
    @doc """
    Get funding history.
    """
    def get(params \\ []) do
      non_auth_get("/funding", params)
    end
  end

  defmodule Quote do
    @doc """
    Get quotes.
    """
    def get(params \\ []) do
      non_auth_get("/quote", params)
    end

    @doc """
    Get previous quotes in time buckets.
    """
    def bucketed(params \\ []) do
      non_auth_get("/quote/bucketed", params)
    end
  end

  defmodule Settlement do
    @doc """
    Get settlement history.
    """
    def get(params \\ []) do
      non_auth_get("/settlement", params)
    end
  end

  defmodule Stats do
    @doc """
    Get exchange-wide and per-series turnover and volume statistics.
    """
    def get(params \\ []) do
      non_auth_get("/stats", params)
    end

    @doc """
    Get historical exchange-wide and per-series turnover and volume statistics.
    """
    def history(params) do
      non_auth_get("/stats", params)
    end
  end

  defmodule Trade do
    @doc """
    Get trades.
    """
    def get(params \\ []) do
      non_auth_get("/trade", params)
    end

    @doc """
    Get previous trades in time buckets.
    """
    def bucketed(params) do
      non_auth_get("/trade/bucketed", params)
    end
  end
end
