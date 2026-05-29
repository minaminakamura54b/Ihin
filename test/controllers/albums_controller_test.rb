require "test_helper"

class AlbumsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @user  = create(:user)
    @other = create(:user)
    @album = create(:album, user: @user)
    sign_in @user
  end

  # ===== 認証チェック =====

  test "未ログインで index にアクセスするとリダイレクト" do
    sign_out @user
    get albums_path
    assert_redirected_to new_user_session_path
  end

  test "未ログインで show にアクセスするとリダイレクト" do
    sign_out @user
    get album_path(@album)
    assert_redirected_to new_user_session_path
  end

  # ===== index =====

  test "index が 200 を返す" do
    get albums_path
    assert_response :success
  end

  # ===== show =====

  test "自分のアルバムを show できる" do
    get album_path(@album)
    assert_response :success
  end

  test "他人のアルバムは show できない" do
    other_album = create(:album, user: @other)
    get album_path(other_album)
    assert_response :not_found
  end

  # ===== create =====

  test "アルバムを作成できる" do
    assert_difference "Album.count", 1 do
      post albums_path, params: { album: { title: "新しいアルバム" } }
    end
    assert_redirected_to album_path(Album.last)
  end

  test "タイトル未入力では作成できない" do
    assert_no_difference "Album.count" do
      post albums_path, params: { album: { title: "" } }
    end
    assert_response :unprocessable_entity
  end

  # ===== destroy =====

  test "アルバムを削除できる" do
    assert_difference "Album.count", -1 do
      delete album_path(@album)
    end
    assert_redirected_to albums_path
  end

  # ===== upload_photo =====

  test "画像をアップロードするとアルバムに追加される" do
    image = fixture_file_upload(
      Rails.root.join("test/fixtures/files/test_image.jpg"), "image/jpeg"
    )
    assert_difference [ "Memory.count", "AlbumMemory.count" ], 1 do
      post upload_photo_album_path(@album), params: { photos: [ image ] }
    end
    assert_redirected_to album_path(@album)
    assert_match "1枚", flash[:notice]
  end

  test "複数画像をまとめてアップロードできる" do
    images = Array.new(3) do
      fixture_file_upload(
        Rails.root.join("test/fixtures/files/test_image.jpg"), "image/jpeg"
      )
    end
    assert_difference [ "Memory.count", "AlbumMemory.count" ], 3 do
      post upload_photo_album_path(@album), params: { photos: images }
    end
    assert_redirected_to album_path(@album)
    assert_match "3枚", flash[:notice]
  end

  test "画像なしでアップロードするとアラートが出る" do
    assert_no_difference [ "Memory.count", "AlbumMemory.count" ] do
      post upload_photo_album_path(@album), params: { photos: [] }
    end
    assert_redirected_to album_path(@album)
    assert flash[:alert].present?
  end

  test "画像以外のファイルはアップロードできない" do
    txt = fixture_file_upload(
      Rails.root.join("test/fixtures/files/test.txt"), "text/plain"
    )
    assert_no_difference [ "Memory.count", "AlbumMemory.count" ] do
      post upload_photo_album_path(@album), params: { photos: [ txt ] }
    end
    assert_redirected_to album_path(@album)
    assert flash[:alert].present?
  end

  test "他人のアルバムには upload_photo できない" do
    other_album = create(:album, user: @other)
    image = fixture_file_upload(
      Rails.root.join("test/fixtures/files/test_image.jpg"), "image/jpeg"
    )
    post upload_photo_album_path(other_album), params: { photos: [ image ] }
    assert_response :not_found
  end

  # ===== add_memories =====

  test "既存の思い出をアルバムに追加できる" do
    memory = create(:memory, user: @user)
    assert_difference "AlbumMemory.count", 1 do
      post add_memories_album_path(@album), params: { memory_ids: [ memory.id ] }
    end
    assert_redirected_to album_path(@album)
  end

  test "他人の思い出はアルバムに追加できない" do
    other_memory = create(:memory, user: @other)
    assert_no_difference "AlbumMemory.count" do
      post add_memories_album_path(@album), params: { memory_ids: [ other_memory.id ] }
    end
  end

  # ===== remove_memory =====

  test "アルバムから写真を削除できる" do
    memory = create(:memory, user: @user)
    AlbumMemory.create!(album: @album, memory: memory)
    assert_difference "AlbumMemory.count", -1 do
      delete remove_memory_album_path(@album, memory_id: memory.id)
    end
  end
end
