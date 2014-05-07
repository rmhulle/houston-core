class ValueStatement < ActiveRecord::Base
  
  belongs_to :project
  validates :project_id, :weight, presence: true
  validates :text, length: 2..36
  
end
