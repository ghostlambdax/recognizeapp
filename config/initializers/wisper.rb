# https://github.com/krisleech/wisper#global-listeners
# These are globally defined listeners
Wisper.subscribe(SlackNotifierListener.new, scope: :Company, prefix: :on)#, async: true)
Wisper.subscribe(SlackNotifierListener.new, scope: :Redemption, prefix: :on)
Wisper.subscribe(RecognitionSmsNotifier.new, scope: :RecognitionAsyncService, prefix: :on)
Wisper.subscribe(MobilePushListener.new, scope: :RecognitionAsyncService, prefix: :on)
Wisper.subscribe(FbWorkplaceListener.new, scope: :RecognitionAsyncService, prefix: :on)
Wisper.subscribe(Webhook::Listener.new, scope: [:Redemption, :RecognitionAsyncService], prefix: :on)
