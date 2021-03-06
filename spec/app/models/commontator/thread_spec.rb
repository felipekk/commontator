require 'spec_helper'

module Commontator
  describe Thread do
    before do
      setup_model_spec
    end

    it 'must have a config' do
      @thread.config.must_be_instance_of CommontableConfig
      @thread.update_attribute(:commontable_id, nil)
      Thread.find(@thread.id).config.must_equal Commontator
    end
    
    it 'must order all comments' do
      comment = Comment.new
      comment.thread = @thread
      comment.creator = @user
      comment.body = 'Something'
      comment.save!
      comment2 = Comment.new
      comment2.thread = @thread
      comment2.creator = @user
      comment2.body = 'Something else'
      comment2.save!
      
      comments = @thread.comments
      ordered_comments = @thread.ordered_comments
      
      comments.each { |c| ordered_comments.must_include c }
      ordered_comments.each { |oc| comments.must_include oc }
    end
    
    it 'must list all subscribers' do
      @thread.subscribe(@user)
      @thread.subscribe(DummyUser.create)
      
      @thread.subscriptions.each { |sp| \
        @thread.subscribers.must_include sp.subscriber }
    end
    
    it 'must find the subscription for each user' do
      @thread.subscribe(@user)
      user2 = DummyUser.create
      @thread.subscribe(user2)
      
      subscription = @thread.subscription_for(@user)
      subscription.thread.must_equal @thread
      subscription.subscriber.must_equal @user
      subscription = @thread.subscription_for(user2)
      subscription.thread.must_equal @thread
      subscription.subscriber.must_equal user2
    end
    
    it 'must know if it is closed' do
      @thread.is_closed?.must_equal false
      
      @thread.close(@user)
      
      @thread.is_closed?.must_equal true
      @thread.closer.must_equal @user
      
      @thread.reopen
      
      @thread.is_closed?.must_equal false
    end
    
    it 'must mark comments as read' do
      @thread.subscribe(@user)

      subscription = @thread.subscription_for(@user)
      subscription.unread_comments.count.must_equal 0

      comment = Comment.new
      comment.thread = @thread
      comment.creator = @user
      comment.body = 'Something'
      comment.save!
      
      subscription.reload.unread_comments.count.must_equal 1
      
      @thread.mark_as_read_for(@user)
      
      subscription.reload.unread_comments.count.must_equal 0
    end
    
    it 'must be able to clear comments' do
      comment = Comment.new
      comment.thread = @thread
      comment.creator = @user
      comment.body = 'Something'
      comment.save!
 
      @thread.close(@user)

      @thread.commontable.must_equal @commontable
      @thread.comments.must_include comment
      @thread.is_closed?.must_equal true
      @thread.closer.must_equal @user

      @commontable = DummyModel.find(@commontable.id)
      @commontable.thread.must_equal @thread

      @thread.clear
      
      @thread.commontable.must_be_nil
      @thread.comments.must_include comment

      @commontable = DummyModel.find(@commontable.id)
      @commontable.thread.wont_be_nil
      @commontable.thread.wont_equal @thread
      @commontable.thread.comments.wont_include comment
    end

    it 'must return nil subscription for nil or false subscriber' do
      @thread.subscription_for(nil).must_equal nil
      @thread.subscription_for(false).must_equal nil
    end
  end
end

