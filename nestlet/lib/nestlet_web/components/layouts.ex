defmodule NestletWeb.Layouts do
  @moduledoc """
  This module holds different layouts used by your application.

  See the `layouts` directory for all templates available.
  The "root" layout is a skeleton rendered as part of the
  application router. The "app" layout is set as the default
  layout on both `use NestletWeb, :controller` and
  `use NestletWeb, :live_view`.
  """
  use NestletWeb, :html

  embed_templates "layouts/*"
end
