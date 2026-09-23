require 'spec_helper'

RSpec.describe 'Notepad++ Text Editor App Matrix' do
  it 'properly tracks application theme hex maps' do
    themes = { dark: '#1E1E1E', light: '#FFFFFF' }
    expect(themes[:dark]).to eq('#1E1E1E')
  end

  it 'calculates text lines data lengths smoothly' do
    sample_block = "line1\nline2\nline3"
    expect(sample_block.lines.count).to eq(3)
  end
end
