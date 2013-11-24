Twitarr.BasePostController = Twitarr.ObjectController.extend
  loading: false

  actions:
    delete: (id) ->
      Twitarr.Post.delete(id).done (data) =>
        return alert(data.status) unless data.status is 'ok'
        posts = _(@get('posts')).reject (x) -> x.post_id is id
        @set 'posts', posts
    reload: ->
      @reload()

  reload: ->
    @set 'loading', true
    @get_data_ajax().done((data) =>
      console.log(data.status) unless data.status is 'ok'
      Ember.run =>
        @set 'loading', false
        @set 'model', data
    ).fail( =>
      alert "There was a problem loading the posts from the server."
      @set 'loading', false
    )
