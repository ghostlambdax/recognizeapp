scope "/stream" do
  get "/comments", to: 'stream_async_load#comments', as: 'stream_comments'
  get "/approvals", to: 'stream_async_load#approvals', as: 'stream_approvals'
end
