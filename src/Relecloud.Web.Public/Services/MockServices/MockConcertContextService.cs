﻿using Relecloud.Models.ConcertContext;
using Relecloud.Models.Services;

namespace Relecloud.Web.Services.MockServices
{
    public class MockConcertContextService : IConcertContextService
    {
        public Task<Concert?> GetConcertByIdAsync(int id)
        {
            return Task.FromResult<Concert?>(null);
        }

        public Task<ICollection<Concert>> GetConcertsByIdAsync(ICollection<int> ids)
        {
            return Task.FromResult<ICollection<Concert>>(Array.Empty<Concert>());
        }

        public Task<ICollection<Concert>> GetUpcomingConcertsAsync(int count)
        {
            return Task.FromResult<ICollection<Concert>>(Array.Empty<Concert>());
        }

        public Task<UpdateResult> CreateOrUpdateUserAsync(User user)
        {
            return Task.FromResult(new UpdateResult());
        }

        public Task<CreateResult> CreateConcertAsync(Concert newConcert)
        {
            return Task.FromResult(new CreateResult());
        }

        public Task<UpdateResult> UpdateConcertAsync(Concert model)
        {
            return Task.FromResult(new UpdateResult());
        }

        public Task<DeleteResult> DeleteConcertAsync(int id)
        {
            return Task.FromResult(new DeleteResult());
        }

        public Task<PagedResult<Ticket>> GetAllTicketsAsync(string userId, int skip, int take)
        {
            return Task.FromResult(new PagedResult<Ticket>(new List<Ticket>(), 0));
        }

        public Task<Ticket?> GetTicketByIdAsync(int id)
        {
            return Task.FromResult<Ticket?>(null);
        }

        public Task<User?> GetUserByIdAsync(string id)
        {
            return Task.FromResult<User?>(null);
        }
    }
}
