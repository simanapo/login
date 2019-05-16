class PagesController < ApplicationController
  before_action :sign_in_required, only: [:show]
  before_action :set_task, only: %i[update_confirm update destroy sort]
  SESSION_KEY_FOR_PARAM = :page

  def index
  end

  def show
    # if params[:user_id].present?
    #   # プルダウンで選択された企業
    #   @company = Company.find(params[:user_id])

    #   @subsidiary_company_options = Company.where(parent_user_id: @company.id)&.is_not_old.pluck(:company_name, :id)
    #   subsidiary_user_ids = @subsidiary_company_options.map { |c| c[1] }

    #   # 子会社選択した場合
    #   @company = Company.find(params[:subsidiary_user_id]) if subsidiary_user_ids.include?(params[:subsidiary_user_id].to_i)
    #   @tasks = @company.tasks.is_not_old.rank(:display_order) if @company&.tasks&.is_not_old
    # end

    @tasks = Task.all
    @task = Task.new
  end

  def search
  end

  # D&Dで並べ替えるためのメソッド
  def sort
    @task.update(task_params)
    render body: nil
  end

  def confirm
    respond_to do |format|
      # プルダウンで選択された企業
      @user = ::User.find(current_user.id)
      task = @user.tasks.build(task_params)
      task = validate_on_confirm(task)

      if task.errors.blank?
        session[SESSION_KEY_FOR_PARAM] = task_params
        format.json { render json: task, status: :ok }
      else
        format.json { fail AsyncRetryValidationError, task.errors }
      end
    end
  end

  def update_confirm
    respond_to do |format|
      @task.assign_attributes(task_params)
      task = validate_on_confirm(@task, task_params[:updated_at])
      if task.errors.blank?
        session[SESSION_KEY_FOR_PARAM] = task_params
        format.json { render json: task, status: :ok }
      else
        format.json { fail AsyncRetryValidationError, task.errors }
      end
    end
  end

  # POST /admin/tasks
  # POST /admin/tasks.json
  def create
    respond_to do |format|
      request = session[SESSION_KEY_FOR_PARAM]
      task = Tasks::Register.new
      task.insert(request, current_user.id)
      session[SESSION_KEY_FOR_PARAM] = nil
      format.json { render json: task, status: :ok }
    end
  end

  # PATCH/PUT /admin/tasks/1
  # PATCH/PUT /admin/tasks/1.json
  def update
    respond_to do |format|
      request = session[SESSION_KEY_FOR_PARAM]
      task = Tasks::Register.new(@task).update(request, @task.user_id, params[:id])
      session[SESSION_KEY_FOR_PARAM] = nil
      format.json { render json: task, status: :ok }
    end
  end

  # DELETE /admin/tasks/1
  # DELETE /admin/tasks/1.json
  def destroy
    respond_to do |format|
      request = {}
      request[:updated_at] = params[:updated_at]
      task = Tasks::Register.new(@task).delete(request, @task.user_id, params[:id])
      if task.errors.blank?
        format.json { render json: task, status: :ok }
      else
        format.json { fail AsyncRetryValidationError, task.errors }
      end
    end
  end

  def csv_upload
    respond_to do |format|
      csv_manager = CsvManager.new
      csv_manager.upload(params[:file])
      if csv_manager.valid?
        format.json { render json: { file_path: csv_manager.file_path, character_code: csv_manager.character_code.to_s }, status: :ok }
      else
        format.json { render json: csv_manager.errors, status: :internal_server_error }
      end
    end
  end

  def csv_load
    # 初回のみ大量データが予想されるのでタイムアウト時間を上書き指定する(秒)
    config.timeout = Rails.application.config.time_out
    respond_to do |format|
      csv_manager = CsvManager.new(params[:csv_file_path])
      if params[:csv_file_path].present? && current_user.id.present?
        begin
          result = Tasks::Register.new.insert_all(
            csv_manager.read_csv(params[:csv_character_code]),
            current_user.id
          )
          # 成功
          format.json { render json: result, status: :ok }
        rescue => e
          # 失敗
          format.json { render json: e.message, status: :unprocessable_entity }
        end
      else
        errors = {}
        errors[:file_unselected] = 'CSVファイルまたは企業を選択してください'
        format.json { render json: errors, status: :internal_server_error }
      end
    end
  end

  # D&Dで並べ替えるためのメソッド
  def sort
    @task.update(task_params)
    render body: nil
  end

  private

  # パラメータから取得したIDから、使用地を取得
  # @return [Object] @task 使用地オブジェクト
  def set_task
    @task = Task.find(params[:id])
  end

  # パラメータ取得
  # @return [Hash] params パラメータ
  # @note ストロングパラメータ
  def task_params
    params.require(:task).permit(
      :task_name,
      :task_detail,
      :updated_at,
      :display_order_position
    )
  end

  # バリデーションチェック
  # @param [Object] task 使用地オブジェクト
  # @param [DateTime] updated_at 更新日時
  # @return [Object] task 使用地オブジェクト
  def validate_on_confirm(task, updated_at = nil)
    task.validate
    task_name_duplicated = call_task_name_duplicated?(updated_at) if updated_at.present?
    task_name_duplicated = call_task_name_duplicated? unless updated_at.present?
    task.errors.add(
      :task_name,
      I18n.t('errors.messages.uniqueness', value: task_params[:task_name])
    ) if task_name_duplicated
    task
  end

  # 使用地重複チェックを呼び出す
  # @param [DateTime] updated_at 更新日時
  # @return [Bool] 重複している場合はtrue、重複していない場合はfalse
  def call_task_name_duplicated?(updated_at = nil)
    if updated_at.nil?
      Task.task_name_duplicated?(
        current_user.id,
        task_params[:task_name]
      )
    else
      Task.task_name_duplicated_for_edit?(
        params[:id],
        current_user.id,
        task_params[:task_name]
      )
    end
  end
end
