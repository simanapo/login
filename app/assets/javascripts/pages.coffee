class PagesController

  update_path = ''

  # タイムアウト
  time_out = ''

  # 左ナビをアクティブにする
  nav_active: ->
    $('#nav-place > a').addClass('menu_active')
    return

  index: ->
    self = this
    # エラー表示
    show_error_message = (element, error_messages) ->
      element.addClass 'error_block'
      element.find('p').remove()

      for error_message in error_messages
        element.append '<p>' + error_message.message + '</p>'
      return
    # 使用地登録 確認
    $('[data-method="confirm"]')
      .on 'ajax:success', (event, data, status, xhr)->
        data = $.parseJSON(xhr.responseText)
        $('[data-remodal-id="modal01"]').remodal().open()
        return
      .on 'ajax:error', (event, xhr, status, error)->
        data = $.parseJSON(xhr.responseText)
        element = $('[data-method="regist_error_message"]')
        show_error_message element, data.errors
        return

    # 使用地登録 登録
    $('[data-method="create"]')
      .on 'ajax:success', (event, data, status, xhr)->
        data = $.parseJSON(xhr.responseText)
        $('[data-remodal-id="modal02"]').remodal().open()
        return
      .on 'ajax:error', (event, xhr, status, error)->
        Application.show_error_modal(xhr)
        return

    # 使用地更新 確認
    $('[data-method="update_confirm"]')
      .on 'ajax:success', (event, data, status, xhr)->
        data = $.parseJSON(xhr.responseText)
        modal = $('[data-remodal-id="edit03-1"]')
        modal.remodal().open()
        modal.find('form').attr('action', self.update_path + '/' + data.id)
        return
      .on 'ajax:error', (event, xhr, status, error)->
        data = $.parseJSON(xhr.responseText)
        element = $(@).find('[data-method="update_error_message"]')
        show_error_message element, data.errors
        return

    # 使用地更新 登録
    $('[data-method="update"]')
      .on 'ajax:success', (event, data, status, xhr)->
        data = $.parseJSON(xhr.responseText)
        $('[data-remodal-id="edit03-3"]').remodal().open()
        return
      .on 'ajax:error', (event, xhr, status, error)->
        Application.show_error_modal(xhr)
        return

    # 使用地削除 確認
    $('[data-method="delete_confirm"]')
      .click ->
        modal = $('[data-remodal-id="delete03-1"]')
        path = self.update_path + '/' + $(@).attr('delete_id')
        updated_at = 'input[name="updated_at"]'
        modal.find('form').attr('action', path)
        modal.find('form').find(updated_at).val($(@).attr('updated_at'))
        modal.remodal().open()
        return

    # 使用地 削除　登録
    $('[data-method="delete"]')
      .on 'ajax:success', (event, data, status, xhr)->
        data = $.parseJSON(xhr.responseText)
        $('[data-remodal-id="delete03-2"]').remodal().open()
        return
      .on 'ajax:error', (event, xhr, status, error)->
        Application.show_error_modal(xhr)
        return


    # 登録完了モーダルを閉じる
    $('[data-method="register_complete"]')
      .click ->
        $('[data-remodal-id="modal02"]').remodal().close()
        Turbolinks.visit(location.toString())
        return

    # 更新完了モーダルを閉じる
    $('[data-method="update_complete"]')
      .click ->
        $('[data-remodal-id="modal02"]').remodal().close()
        Turbolinks.visit(location.toString())
        return

    # 削除完了モーダルを閉じる
    $('[data-method="delete_complete"]')
      .click ->
        $('[data-remodal-id="delete03-2"]').remodal().close()
        Turbolinks.visit(location.toString())
        return

    return

this.Application.pages = new PagesController
