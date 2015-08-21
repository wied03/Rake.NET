#region

using System;
using System.Linq;
using System.Linq.Expressions;
using System.Web.Mvc;
using MvcApplication1.Controllers;
using NUnit.Framework;
using FluentAssertions;

#endregion

namespace MvcApplication1.Test
{
    [TestFixture]
    public class Default1ControllerTest 
    {
        [Test]
        public void Index()
        {
            // arrange
            var controller = new Default1Controller();

            // act
            var result = controller.Index();

            // assert
            result
                .Should()
                .BeOfType<ViewResult>();

        }
    }
}