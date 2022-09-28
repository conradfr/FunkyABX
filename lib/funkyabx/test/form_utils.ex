defmodule FunkyABX.Tests.FormUtils do
  # ---------- TEST PARAMS ----------

  def update_test_params("ranking", %{"ranking" => ranking} = test_params)
      when ranking == "true" do
    test_params
    |> Map.put("picking", false)
    |> Map.put("starring", false)
  end

  def update_test_params("picking", %{"picking" => picking} = test_params)
      when picking == "true" do
    test_params
    |> Map.put("ranking", false)
    |> Map.put("starring", false)
  end

  def update_test_params("starring", %{"starring" => starring} = test_params)
      when starring == "true" do
    test_params
    |> Map.put("ranking", false)
    |> Map.put("picking", false)
  end

  def update_test_params(_target, test_params) do
    test_params
  end
end
