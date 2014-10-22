class Work < ActiveRecord::Base
  extend Enumerize

  enumerize :media, in: { tv: 1, ova: 2, movie: 3, web: 4, other: 0 }
  has_paper_trail

  belongs_to :season
  has_many   :episodes, dependent: :destroy
  has_many   :items,    dependent: :destroy
  has_many   :programs, dependent: :destroy
  has_many   :statuses, dependent: :destroy

  validates :media, presence: true
  validates :title, presence: true, uniqueness: true

  scope :by_season, -> (season_slug) {
    return self if season_slug.blank?

    season = Season.find_by(slug: season_slug)

    return none if season.blank?

    where(season_id: season.id)
  }

  scope :on_air, -> { where(on_air: true) }

  scope :program_registered, -> {
    work_ids = joins(:programs).merge(Program.where(work_id: all.pluck(:id))).pluck(:id).uniq
    where(id: work_ids)
  }

  scope :broadcasted_on_nicoch, -> { where('nicoch_started_at IS NOT NULL') }

  before_save :change_to_utc_datetime


  # 作品のエピソード数分の空白文字列が入った配列を返す
  # Chart.jsのx軸のラベルを消すにはこれしか方法がなかったんだ…! たぶん…。
  def chart_labels
    episodes.pluck(:id).map {''}
  end

  def chart_values
    episodes.order(:sort_number).pluck(:checkins_count)
  end

  def checkins_count
    chart_values.reduce(&:+).presence || 0
  end

  def main_item
    items.find_by(main: true).presence || Item.find(1)
  end

  def latest_statuses
    statuses.where(latest: true)
  end

  def comments_count
    episode_ids = episodes.pluck(:id)
    checkins = Checkin.where(episode_id: episode_ids).where('comment != ?', '')

    checkins.count
  end

  def twitter_url
    twitter_username.present? ? "https://twitter.com/#{twitter_username}" : ''
  end

  def twitter_hashtag_url
    twitter_hashtag.present? ? URI.encode("https://twitter.com/search?q=#{twitter_hashtag}&src=hash") : ''
  end

  def syobocal_url
    "http://cal.syoboi.jp/tid/#{sc_tid}"
  end

  def channels
    if episodes.present?
      programs = Program.where(episode_id: episodes.order(:sort_number).first.id)
      Channel.where(id: programs.pluck(:channel_id).uniq) if programs.present?
    end
  end

  def broadcast_on_nicoch?
    nicoch_started_at.present?
  end


  private

  # データベースには標準時 (UTC) を保存する
  def change_to_utc_datetime
    self.nicoch_started_at = nicoch_started_at.try(:-, (Time.now.utc_offset))
  end
end
