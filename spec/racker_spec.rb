feature Racker do
  background do
    visit '/'
  end

  scenario 'Visit index page' do
    expect(page).to have_content('Here can be your advertising')
  end

  scenario 'Start new game' do
    click_link('New game')
    expect(page).to have_content('Game status: Playing')
  end

  scenario 'Try to guess code' do
    click_link('New game')
    fill_in('answer', with: '1111')
    click_button('Answer')
    expect(page).to have_selector('table.grid')
  end

  scenario 'Try to get hint' do
    click_link('New game')
    click_link('Take hint')
    expect(page).to have_content('The code begins with')
    expect(page).not_to have_content('Take hint')
  end

  scenario 'Lose the game' do
    click_link('New game')
    5.times do
      fill_in('answer', with: '1111')
      click_button('Answer')
    end
    expect(page).to have_content('Game status: Game over')
  end

  scenario 'Guess code and save results' do
    click_link('New game')
    fill_in('answer', with: '12qw')
    click_button('Answer')
    expect(page).to have_content('You have to enter four digits')

    fill_in('answer', with: Capybara.string(page.body).find('span.code_value').text)
    click_button('Answer')
    expect(page).to have_content('Game status: You win!')

    click_link('Save results')
    click_button('Send')
    expect(page).to have_content('Name cannot contain less')

    fill_in('user_name', with: 'az')
    expect(page).to have_content('Name cannot contain less')

    user_name = rand(36**8).to_s(36)
    fill_in('user_name', with: user_name)
    click_button('Send')
    expect(page).to have_selector('table.grid')
    expect(page).to have_content(user_name)
  end

  scenario 'Load saved results' do
    click_link('Load saved results')
    expect(page.status_code).to be(200)
  end
end
